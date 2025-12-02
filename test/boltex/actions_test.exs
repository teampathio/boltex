defmodule Boltex.ActionsTest do
  use ExUnit.Case, async: true

  import Tesla.Mock

  alias Boltex.Actions
  alias Boltex.Client
  alias Boltex.Events.Context

  setup do
    client = Client.new("xoxb-test-token")

    context = %Context{
      client: client,
      team_id: "T123ABC456",
      user_id: "U123ABC456",
      channel_id: "C123ABC456"
    }

    {:ok, context: context}
  end

  describe "say/2" do
    test "posts message to context channel", %{context: context} do
      mock(fn %{method: :post, url: "https://slack.com/api/chat.postMessage", body: body} ->
        decoded = Jason.decode!(body)
        assert decoded["channel"] == "C123ABC456"
        assert decoded["text"] == "Hello, world!"

        %Tesla.Env{
          status: 200,
          body: %{
            "ok" => true,
            "channel" => "C123ABC456",
            "ts" => "1234567890.123456"
          }
        }
      end)

      assert {:ok, response} = Actions.say(context, %{text: "Hello, world!"})
      assert response["ok"] == true
    end

    test "passes through blocks and other arguments", %{context: context} do
      mock(fn %{method: :post, body: body} ->
        decoded = Jason.decode!(body)
        assert decoded["channel"] == "C123ABC456"
        assert decoded["text"] == "Fallback text"
        assert length(decoded["blocks"]) == 1
        assert hd(decoded["blocks"])["type"] == "section"

        %Tesla.Env{
          status: 200,
          body: %{"ok" => true, "ts" => "123.456"}
        }
      end)

      result =
        Actions.say(context, %{
          text: "Fallback text",
          blocks: [
            %{
              type: "section",
              text: %{type: "mrkdwn", text: "*Bold* text"}
            }
          ]
        })

      assert {:ok, _} = result
    end
  end

  describe "publish_home/2" do
    test "publishes view to context user", %{context: context} do
      view = %{
        type: "home",
        blocks: [
          %{
            type: "section",
            text: %{type: "mrkdwn", text: "Welcome home!"}
          }
        ]
      }

      mock(fn %{method: :post, url: "https://slack.com/api/views.publish", body: body} ->
        decoded = Jason.decode!(body)
        assert decoded["user_id"] == "U123ABC456"
        assert decoded["view"]["type"] == "home"

        %Tesla.Env{
          status: 200,
          body: %{
            "ok" => true,
            "view" => %{"id" => "V123ABC456"}
          }
        }
      end)

      assert {:ok, response} = Actions.publish_home(context, view)
      assert response["ok"] == true
      assert response["view"]["id"] == "V123ABC456"
    end
  end

  describe "reply/3" do
    test "replies in thread using ts from payload", %{context: context} do
      payload = %{ts: "1234567890.123456"}

      mock(fn %{method: :post, url: "https://slack.com/api/chat.postMessage", body: body} ->
        decoded = Jason.decode!(body)
        assert decoded["channel"] == "C123ABC456"
        assert decoded["text"] == "Thread reply"
        assert decoded["thread_ts"] == "1234567890.123456"

        %Tesla.Env{
          status: 200,
          body: %{
            "ok" => true,
            "channel" => "C123ABC456",
            "ts" => "1234567890.223456",
            "thread_ts" => "1234567890.123456"
          }
        }
      end)

      assert {:ok, response} = Actions.reply(context, payload, %{text: "Thread reply"})
      assert response["ok"] == true
      assert response["thread_ts"] == "1234567890.123456"
    end

    test "passes through additional arguments", %{context: context} do
      payload = %{ts: "1234567890.123456"}

      mock(fn %{method: :post, body: body} ->
        decoded = Jason.decode!(body)
        assert decoded["thread_ts"] == "1234567890.123456"
        assert decoded["text"] == "Reply"
        assert decoded["mrkdwn"] == true

        %Tesla.Env{
          status: 200,
          body: %{"ok" => true, "ts" => "123.456"}
        }
      end)

      result = Actions.reply(context, payload, %{text: "Reply", mrkdwn: true})
      assert {:ok, _} = result
    end
  end
end
