defmodule Boltex.OAuthController do
  @moduledoc """
  Handles Slack OAuth installation flow.

  ## Configuration

      config :boltex,
        repo: MyApp.Repo,
        signing_secret: "YOUR_SLACK_SIGNING_SECRET",
        client_id: "YOUR_CLIENT_ID",
        client_secret: "YOUR_CLIENT_SECRET",
        scopes: "chat:write,app_mentions:read,channels:read,commands"

  This controller is automatically mounted when using `Boltex.Plug`.
  The app module is passed via `conn.private[:boltex_app]`.
  """

  use Phoenix.Controller, formats: [:html]

  alias Boltex.Installations

  @authorize_url "https://slack.com/oauth/v2/authorize"
  @token_url "https://slack.com/api/oauth.v2.access"

  def install(conn, params) do
    state = generate_state(params)
    conn = put_session(conn, :slack_oauth_state, state)
    oauth_url = build_authorize_url(conn, state)

    redirect(conn, external: oauth_url)
  end

  def callback(conn, %{"code" => code, "state" => state} = _params) do
    session_state = get_session(conn, :slack_oauth_state)
    conn = delete_session(conn, :slack_oauth_state)
    app_module = Boltex.App.get(conn)

    if state != session_state do
      app_module.handle_install_failure(conn, :invalid_state)
    else
      with {:ok, installation_data} <- exchange_code(conn, code),
           installation_params <- build_installation_params(installation_data),
           team_id <- installation_params.team_id do
        reinstall = match?({:ok, _}, Installations.find(team_id))

        case Installations.save(installation_params) do
          {:ok, installation} ->
            {:ok, decoded_state} = decode_state(state)

            metadata = %{
              reinstall: reinstall,
              installation_data: installation_data,
              state: decoded_state.params
            }

            app_module.handle_install_success(conn, installation, metadata)

          {:error, changeset} ->
            app_module.handle_install_failure(conn, {:save_failed, changeset})
        end
      else
        {:error, reason} ->
          app_module.handle_install_failure(conn, {:exchange_failed, reason})
      end
    end
  end

  def callback(conn, %{"error" => error} = _params) do
    Boltex.App.get(conn).handle_install_failure(conn, {:slack_error, error})
  end

  def callback(conn, _params) do
    Boltex.App.get(conn).handle_install_failure(conn, :invalid_params)
  end

  defp generate_state(params) do
    state_data = %{
      nonce: :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false),
      params: params
    }

    state_data
    |> :erlang.term_to_binary()
    |> Base.url_encode64(padding: false)
  end

  defp decode_state(state) do
    try do
      decoded =
        state
        |> Base.url_decode64!(padding: false)
        |> :erlang.binary_to_term([:safe])

      {:ok, decoded}
    rescue
      _ -> {:error, :invalid_state}
    end
  end

  defp build_authorize_url(conn, state) do
    config = boltex_config()
    redirect_uri = build_redirect_uri(conn)

    params = %{
      client_id: config.client_id,
      scope: config.scopes,
      redirect_uri: redirect_uri,
      state: state
    }

    query = URI.encode_query(params)
    "#{@authorize_url}?#{query}"
  end

  defp client do
    middleware = [
      {Tesla.Middleware.FormUrlencoded, []},
      {Tesla.Middleware.JSON, []}
    ]

    Tesla.client(middleware)
  end

  defp exchange_code(conn, code) do
    config = boltex_config()
    redirect_uri = build_redirect_uri(conn)

    body = %{
      client_id: config.client_id,
      client_secret: config.client_secret,
      code: code,
      redirect_uri: redirect_uri
    }

    case Tesla.post(client(), @token_url, body) do
      {:ok, %{status: 200, body: %{"ok" => true} = data}} ->
        {:ok, data}

      {:ok, %{status: 200, body: %{"ok" => false, "error" => error}}} ->
        {:error, error}

      {:ok, response} ->
        {:error, "Unexpected response: #{response.status}"}

      {:error, _} = error ->
        error
    end
  end

  defp build_redirect_uri(conn) do
    uri = URI.parse(Phoenix.Controller.current_url(conn))

    %{uri | path: "/slack/oauth_redirect", query: nil, fragment: nil}
    |> URI.to_string()
  end

  defp build_installation_params(data) do
    %{
      team_id: get_in(data, ["team", "id"]),
      team_name: get_in(data, ["team", "name"]),
      bot_token: data["access_token"],
      bot_user_id: data["bot_user_id"],
      scope: data["scope"],
      authed_user: data["authed_user"],
      enterprise_id: get_in(data, ["enterprise", "id"]),
      is_enterprise_install: data["is_enterprise_install"] || false
    }
  end

  defp boltex_config do
    config = Boltex.config()

    %{
      client_id: Keyword.fetch!(config, :client_id),
      client_secret: Keyword.fetch!(config, :client_secret),
      scopes: Keyword.fetch!(config, :scopes)
    }
  end
end
