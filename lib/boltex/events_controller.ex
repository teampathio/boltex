defmodule Boltex.EventsController do
  @moduledoc """
  Handles incoming Slack events via the Events API.

  This controller is automatically mounted when using `Boltex.Plug`.
  The app module is passed via `conn.private[:boltex_app]`.

  ## Request Signature Verification

  This controller verifies Slack request signatures using the raw request body.
  Ensure your body reader saves the raw body to `conn.private[:raw_body]` for
  the `/slack/events` path.

  ## Example BodyReader

      defmodule MyAppWeb.BodyReader do
        def read_body(%{path_info: ["slack", "events" | _]} = conn, opts) do
          {:ok, body, conn} = Plug.Conn.read_body(conn, opts)
          conn = update_in(conn.private[:raw_body], &[body | &1 || []])
          {:ok, body, conn}
        end

        def read_body(conn, opts), do: Plug.Conn.read_body(conn, opts)
      end

  Configure it in your endpoint:

      plug Plug.Parsers,
        parsers: [:urlencoded, :multipart, :json],
        pass: ["*/*"],
        body_reader: {MyAppWeb.BodyReader, :read_body, []},
        json_decoder: Jason
  """

  use Phoenix.Controller, formats: [:json]

  require Logger

  plug :verify_slack_signature

  def handle(conn, %{"type" => "url_verification", "challenge" => challenge}) do
    json(conn, %{challenge: challenge})
  end

  def handle(conn, params) do
    app_module = Boltex.App.get(conn)

    if allows_sync_response?(params) do
      case process_event(params, app_module, :sync) do
        {:ok, ""} -> send_resp(conn, 200, "")
        {:ok, response} -> json(conn, response)
        :ok -> send_resp(conn, 200, "")
        :ignore -> send_resp(conn, 200, "")
        {:error, reason} -> json(conn |> put_status(500), %{error: reason})
      end
    else
      process_event(params, app_module, :async)
      send_resp(conn, 200, "")
    end
  end

  defp verify_slack_signature(conn, _opts) do
    signing_secret = boltex_config().signing_secret

    with [timestamp] <- get_req_header(conn, "x-slack-request-timestamp"),
         [signature] <- get_req_header(conn, "x-slack-signature"),
         body = get_raw_body(conn),
         {ts_int, _} <- Integer.parse(timestamp),
         current_time = System.system_time(:second),
         true <- abs(current_time - ts_int) <= 300 do
      basestring = "v0:#{timestamp}:#{body}"

      computed =
        :crypto.mac(:hmac, :sha256, signing_secret, basestring)
        |> Base.encode16(case: :lower)

      expected_sig = "v0=#{computed}"

      if Plug.Crypto.secure_compare(expected_sig, signature) do
        conn
      else
        conn
        |> put_status(401)
        |> json(%{error: "invalid_request_signature"})
        |> halt()
      end
    else
      _ ->
        conn
        |> put_status(401)
        |> json(%{error: "invalid_request_signature"})
        |> halt()
    end
  end

  defp get_raw_body(conn) do
    # TODO make raw body placement more configurable
    case conn.private[:raw_body] || conn.assigns[:raw_body] do
      [body | _] when is_binary(body) -> body
      body when is_binary(body) -> body
      _ -> raise "Raw body not found in conn"
    end
  end

  defp allows_sync_response?(%{"type" => "event_callback"}), do: false
  defp allows_sync_response?(_params), do: true

  # Handle interactive components (block_actions, etc.) that come as form-encoded payload
  defp process_event(%{"payload" => payload_json} = _params, app_module, mode)
       when is_binary(payload_json) do
    raw_payload = Jason.decode!(payload_json)
    team_id = get_in(raw_payload, ["team", "id"])
    process_event(Map.put(raw_payload, "team_id", team_id), app_module, mode)
  end

  defp process_event(%{"team_id" => team_id} = raw_payload, app_module, mode) do
    case Boltex.Installations.find_bot_token(team_id) do
      {:ok, bot_token} ->
        event = Boltex.Events.Payload.new(raw_payload)
        ctx = build_context(raw_payload, event, bot_token)
        Boltex.Events.Dispatcher.dispatch(event, ctx, app_module, mode)

      {:error, :not_found} ->
        Logger.warning("Received event for unknown team: #{team_id}")
        {:error, "Team not found"}
    end
  end

  defp build_context(raw_payload, event, bot_token) do
    team_id = raw_payload["team_id"]

    %Boltex.Events.Context{
      team_id: team_id,
      user_id: event.user_id,
      channel_id: Map.get(event, :channel_id),
      bot_token: bot_token,
      client: Boltex.Client.new(bot_token)
    }
  end

  defp boltex_config do
    config = Boltex.config()

    %{
      signing_secret: Keyword.fetch!(config, :signing_secret)
    }
  end
end
