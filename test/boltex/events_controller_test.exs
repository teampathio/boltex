defmodule Boltex.EventsControllerTest do
  use ExUnit.Case, async: false

  import Plug.Test
  import Plug.Conn
  import Mox
  import ExUnit.CaptureLog

  alias Boltex.EventsController

  setup :verify_on_exit!

  defmodule TestApp do
    def middleware, do: []
    def event_handlers, do: []
  end

  setup do
    signing_secret = "test_signing_secret"
    Application.put_env(:boltex, Boltex, signing_secret: signing_secret)

    on_exit(fn ->
      Application.delete_env(:boltex, Boltex)
    end)

    {:ok, signing_secret: signing_secret}
  end

  defp sign_request(body, signing_secret) do
    timestamp = to_string(System.system_time(:second))

    basestring = "v0:#{timestamp}:#{body}"

    signature =
      :crypto.mac(:hmac, :sha256, signing_secret, basestring)
      |> Base.encode16(case: :lower)

    {"v0=#{signature}", timestamp}
  end

  defp build_conn(body, signing_secret) do
    {signature, timestamp} = sign_request(body, signing_secret)

    conn(:post, "/slack/events", body)
    |> put_private(:boltex_app, TestApp)
    |> put_private(:raw_body, [body])
    |> put_req_header("content-type", "application/json")
    |> put_req_header("x-slack-signature", signature)
    |> put_req_header("x-slack-request-timestamp", timestamp)
    |> Plug.Parsers.call(Plug.Parsers.init(parsers: [:json], json_decoder: Jason))
    |> fetch_query_params()
  end

  describe "handle/2 url_verification" do
    test "returns challenge for url_verification", %{signing_secret: signing_secret} do
      body = Jason.encode!(%{type: "url_verification", challenge: "test_challenge_value"})

      conn = build_conn(body, signing_secret)
      conn = EventsController.handle(conn, conn.params)

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == %{"challenge" => "test_challenge_value"}
    end
  end

  describe "handle/2 event_callback" do
    test "processes async event and returns 200", %{signing_secret: signing_secret} do
      Boltex.MockRepo
      |> expect(:one, fn _ -> "xoxb-token" end)

      body =
        Jason.encode!(%{
          type: "event_callback",
          team_id: "T123",
          event: %{
            type: "message",
            user: "U123",
            text: "Hello",
            ts: "1234567890.123456",
            channel: "C123"
          }
        })

      conn = build_conn(body, signing_secret)
      conn = EventsController.handle(conn, conn.params)

      assert conn.status == 200
      assert conn.resp_body == ""
    end

    test "logs warning for unknown team", %{signing_secret: signing_secret} do
      Boltex.MockRepo
      |> expect(:one, fn _ -> nil end)

      body =
        Jason.encode!(%{
          type: "event_callback",
          team_id: "T999",
          event: %{
            type: "message",
            user: "U123",
            text: "Hello",
            ts: "1234567890.123456"
          }
        })

      log =
        capture_log(fn ->
          conn = build_conn(body, signing_secret)
          conn = EventsController.handle(conn, conn.params)

          assert conn.status == 200
        end)

      assert log =~ "unknown team: T999"
    end
  end

  describe "handle/2 block_actions" do
    test "processes sync action and returns response", %{signing_secret: signing_secret} do
      Boltex.MockRepo
      |> expect(:one, fn _ -> "xoxb-token" end)

      defmodule RespondingHandler do
        def handle_sync(_event, _ctx), do: {:ok, %{text: "Action handled"}}
        def handle_async(_event, _ctx), do: :ok
      end

      defmodule RespondingApp do
        def middleware, do: []
        def event_handlers, do: [Boltex.EventsControllerTest.RespondingHandler]
      end

      body =
        Jason.encode!(%{
          type: "block_actions",
          team: %{id: "T123"},
          team_id: "T123",
          user: %{id: "U123"},
          actions: [
            %{
              type: "button",
              action_id: "test_button",
              block_id: "test_block",
              value: "test_value"
            }
          ]
        })

      conn = build_conn(body, signing_secret)
      conn = put_private(conn, :boltex_app, RespondingApp)
      conn = EventsController.handle(conn, conn.params)

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == %{"text" => "Action handled"}
    end

    test "handles form-encoded payload parameter", %{signing_secret: signing_secret} do
      Boltex.MockRepo
      |> expect(:one, fn _ -> "xoxb-token" end)

      defmodule FormEncodedHandler do
        def handle_sync(_event, _ctx), do: {:ok, %{text: "Handled"}}
        def handle_async(_event, _ctx), do: :ok
      end

      defmodule FormEncodedApp do
        def middleware, do: []
        def event_handlers, do: [Boltex.EventsControllerTest.FormEncodedHandler]
      end

      payload_data = %{
        type: "block_actions",
        team: %{id: "T123"},
        user: %{id: "U123"},
        actions: [
          %{
            type: "button",
            action_id: "test_button",
            block_id: "test_block"
          }
        ]
      }

      body = "payload=" <> URI.encode_www_form(Jason.encode!(payload_data))

      {signature, timestamp} = sign_request(body, signing_secret)

      conn =
        conn(:post, "/slack/events", body)
        |> put_private(:boltex_app, FormEncodedApp)
        |> put_private(:raw_body, [body])
        |> put_req_header("content-type", "application/x-www-form-urlencoded")
        |> put_req_header("x-slack-signature", signature)
        |> put_req_header("x-slack-request-timestamp", timestamp)
        |> Plug.Parsers.call(
          Plug.Parsers.init(parsers: [:urlencoded, :json], json_decoder: Jason)
        )
        |> fetch_query_params()

      conn = EventsController.handle(conn, conn.params)

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == %{"text" => "Handled"}
    end
  end

  describe "handle/2 slash commands with halting middleware" do
    test "returns empty 200 when middleware halts sync event", %{signing_secret: signing_secret} do
      Boltex.MockRepo
      |> expect(:one, fn _ -> "xoxb-token" end)

      defmodule HaltingMiddleware do
        def call(_ctx, _event, _opts), do: {:halt, "stopped"}
      end

      defmodule HaltedApp do
        def middleware, do: [Boltex.EventsControllerTest.HaltingMiddleware]
        def event_handlers, do: []
      end

      body =
        Jason.encode!(%{
          command: "/test",
          text: "hello",
          team_id: "T123",
          user_id: "U123",
          user_name: "testuser",
          channel_id: "C123",
          channel_name: "general",
          team_domain: "test",
          response_url: "https://hooks.slack.com/commands/123/456",
          trigger_id: "123.456"
        })

      conn = build_conn(body, signing_secret)
      conn = put_private(conn, :boltex_app, HaltedApp)

      log =
        capture_log(fn ->
          conn = EventsController.handle(conn, conn.params)

          assert conn.status == 200
          assert conn.resp_body == ""
        end)

      assert log =~ "halted"
    end
  end

  describe "handle/2 with ack()" do
    test "returns empty 200 when handler calls ack()", %{signing_secret: signing_secret} do
      Boltex.MockRepo
      |> expect(:one, fn _ -> "xoxb-token" end)

      defmodule AckHandler do
        import Boltex.Actions

        def handle_sync(_event, _ctx), do: ack()
        def handle_async(_event, _ctx), do: :ok
      end

      defmodule AckApp do
        def middleware, do: []
        def event_handlers, do: [Boltex.EventsControllerTest.AckHandler]
      end

      body =
        Jason.encode!(%{
          command: "/test",
          text: "hello",
          team_id: "T123",
          user_id: "U123",
          user_name: "testuser",
          channel_id: "C123",
          channel_name: "general",
          team_domain: "test",
          response_url: "https://hooks.slack.com/commands/123/456",
          trigger_id: "123.456"
        })

      conn = build_conn(body, signing_secret)
      conn = put_private(conn, :boltex_app, AckApp)
      conn = EventsController.handle(conn, conn.params)

      assert conn.status == 200
      assert conn.resp_body == ""
    end

    test "returns JSON response when handler calls ack(text)", %{signing_secret: signing_secret} do
      Boltex.MockRepo
      |> expect(:one, fn _ -> "xoxb-token" end)

      defmodule AckTextHandler do
        import Boltex.Actions

        def handle_sync(_event, _ctx), do: ack("Got it!")
        def handle_async(_event, _ctx), do: :ok
      end

      defmodule AckTextApp do
        def middleware, do: []
        def event_handlers, do: [Boltex.EventsControllerTest.AckTextHandler]
      end

      body =
        Jason.encode!(%{
          command: "/test",
          text: "hello",
          team_id: "T123",
          user_id: "U123",
          user_name: "testuser",
          channel_id: "C123",
          channel_name: "general",
          team_domain: "test",
          response_url: "https://hooks.slack.com/commands/123/456",
          trigger_id: "123.456"
        })

      conn = build_conn(body, signing_secret)
      conn = put_private(conn, :boltex_app, AckTextApp)
      conn = EventsController.handle(conn, conn.params)

      assert conn.status == 200
      assert Jason.decode!(conn.resp_body) == %{"text" => "Got it!"}
    end
  end
end
