defmodule Boltex.Client.ApiTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog
  import Tesla.Mock

  alias Boltex.Client
  alias Boltex.Client.Api
  alias Boltex.Client.ApiError

  setup do
    client = Client.new("xoxb-test-token")
    {:ok, client: client}
  end

  describe "chat_post_message/3" do
    test "posts a message successfully", %{client: client} do
      mock(fn %{method: :post, url: "https://slack.com/api/chat.postMessage", body: body} ->
        decoded = Jason.decode!(body)
        assert decoded["channel"] == "C1234567890"
        assert decoded["text"] == "Hello, world!"

        %Tesla.Env{
          status: 200,
          body: %{
            "ok" => true,
            "channel" => "C1234567890",
            "ts" => "1234567890.123456",
            "message" => %{"text" => "Hello, world!"}
          }
        }
      end)

      assert {:ok, response} =
               Api.chat_post_message(client, "C1234567890", %{text: "Hello, world!"})

      assert response["ok"] == true
      assert response["channel"] == "C1234567890"
    end

    test "handles Slack API errors", %{client: client} do
      mock(fn %{method: :post, url: "https://slack.com/api/chat.postMessage"} ->
        %Tesla.Env{
          status: 200,
          body: %{
            "ok" => false,
            "error" => "channel_not_found"
          },
          opts: [
            req_url: "https://slack.com/api/chat.postMessage",
            req_body: "{\"channel\":\"C999\",\"text\":\"Hello\"}"
          ]
        }
      end)

      capture_log(fn ->
        assert {:error, %ApiError{} = error} =
                 Api.chat_post_message(client, "C999", %{text: "Hello"})

        assert error.error == "channel_not_found"
      end)
    end

    test "handles non-200 responses", %{client: client} do
      mock(fn %{method: :post, url: "https://slack.com/api/chat.postMessage"} ->
        %Tesla.Env{status: 500, body: "Internal Server Error"}
      end)

      assert {:error, %Tesla.Env{status: 500}} =
               Api.chat_post_message(client, "C1234", %{text: "Hello"})
    end
  end

  describe "chat_update/4" do
    test "updates a message successfully", %{client: client} do
      mock(fn %{method: :post, url: "https://slack.com/api/chat.update", body: body} ->
        decoded = Jason.decode!(body)
        assert decoded["channel"] == "C1234567890"
        assert decoded["ts"] == "1234567890.123456"
        assert decoded["text"] == "Updated text"

        %Tesla.Env{
          status: 200,
          body: %{
            "ok" => true,
            "channel" => "C1234567890",
            "ts" => "1234567890.123456",
            "text" => "Updated text"
          }
        }
      end)

      assert {:ok, response} =
               Api.chat_update(client, "C1234567890", "1234567890.123456", %{text: "Updated text"})

      assert response["ok"] == true
      assert response["text"] == "Updated text"
    end
  end

  describe "views_publish/4" do
    test "publishes a view successfully", %{client: client} do
      view = %{
        type: "home",
        blocks: [%{type: "section", text: %{type: "mrkdwn", text: "Welcome!"}}]
      }

      mock(fn %{method: :post, url: "https://slack.com/api/views.publish", body: body} ->
        decoded = Jason.decode!(body)
        assert decoded["user_id"] == "U1234567890"
        assert decoded["view"]["type"] == "home"

        %Tesla.Env{
          status: 200,
          body: %{
            "ok" => true,
            "view" => %{"id" => "V123"}
          }
        }
      end)

      assert {:ok, response} = Api.views_publish(client, "U1234567890", view)
      assert response["ok"] == true
      assert response["view"]["id"] == "V123"
    end
  end

  describe "users_info/3" do
    test "retrieves user info successfully", %{client: client} do
      mock(fn %{method: :get, url: url} ->
        assert url =~ "https://slack.com/api/users.info"
        assert url =~ "user=U1234567890"

        %Tesla.Env{
          status: 200,
          body: %{
            "ok" => true,
            "user" => %{
              "id" => "U1234567890",
              "name" => "test_user",
              "real_name" => "Test User"
            }
          }
        }
      end)

      assert {:ok, response} = Api.users_info(client, "U1234567890")
      assert response["ok"] == true
      assert response["user"]["name"] == "test_user"
    end
  end

  describe "conversations_join/3" do
    test "joins a conversation successfully", %{client: client} do
      mock(fn %{method: :post, url: "https://slack.com/api/conversations.join", body: body} ->
        decoded = Jason.decode!(body)
        assert decoded["channel"] == "C1234567890"

        %Tesla.Env{
          status: 200,
          body: %{
            "ok" => true,
            "channel" => %{
              "id" => "C1234567890",
              "name" => "general"
            }
          }
        }
      end)

      assert {:ok, response} = Api.conversations_join(client, "C1234567890")
      assert response["ok"] == true
      assert response["channel"]["name"] == "general"
    end
  end

  describe "authentication" do
    test "includes bearer token in requests", %{client: client} do
      mock(fn env ->
        auth_header = Enum.find(env.headers, fn {key, _} -> key == "authorization" end)
        assert {"authorization", "Bearer xoxb-test-token"} = auth_header

        %Tesla.Env{
          status: 200,
          body: %{"ok" => true}
        }
      end)

      Api.chat_post_message(client, "C123", %{text: "test"})
    end
  end

  describe "error handling" do
    test "handles network errors", %{client: client} do
      mock(fn _ ->
        {:error, :timeout}
      end)

      assert {:error, :timeout} = Api.chat_post_message(client, "C123", %{text: "test"})
    end

    test "handles Slack errors with response metadata", %{client: client} do
      mock(fn _ ->
        %Tesla.Env{
          status: 200,
          body: %{
            "ok" => false,
            "error" => "invalid_auth",
            "response_metadata" => %{
              "messages" => ["token is invalid"],
              "warnings" => ["some warning"]
            }
          },
          opts: [
            req_url: "https://slack.com/api/chat.postMessage",
            req_body: "{\"channel\":\"C123\",\"text\":\"test\"}"
          ]
        }
      end)

      capture_log(fn ->
        assert {:error, %ApiError{} = error} =
                 Api.chat_post_message(client, "C123", %{text: "test"})

        assert error.error == "invalid_auth"
        assert error.messages == ["token is invalid"]
        assert error.warnings == ["some warning"]
      end)
    end
  end
end
