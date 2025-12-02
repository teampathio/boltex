defmodule Boltex.Events.PayloadTest do
  use ExUnit.Case, async: true

  alias Boltex.Events.Payload

  describe "new/1 with event payload" do
    test "creates Event struct from app_home_opened event" do
      payload = %{
        "event" => %{
          "type" => "app_home_opened",
          "user" => "U123ABC456",
          "channel" => "D123ABC456",
          "event_ts" => "1515449522000016",
          "tab" => "home",
          "view" => %{
            "id" => "V123ABC456",
            "team_id" => "T123ABC456",
            "type" => "home",
            "blocks" => [
              %{
                "type" => "section",
                "text" => %{
                  "type" => "mrkdwn",
                  "text" => "Welcome to the app home!"
                }
              }
            ],
            "private_metadata" => "",
            "callback_id" => "",
            "hash" => "1231232323.12321312",
            "clear_on_close" => false,
            "notify_on_close" => false,
            "root_view_id" => "V123ABC456",
            "app_id" => "A123ABC456",
            "external_id" => "",
            "app_installed_team_id" => "T123ABC456",
            "bot_id" => "B123ABC456"
          }
        }
      }

      assert %Payload.Event{} = event = Payload.new(payload)
      assert event.type == "app_home_opened"
      assert event.user_id == "U123ABC456"
      assert event.channel_id == "D123ABC456"
      assert event.ts == "1515449522000016"
      assert event.tab == "home"
      assert event.view["id"] == "V123ABC456"
      assert event.view["type"] == "home"
    end

    test "creates Event struct from message event" do
      payload = %{
        "event" => %{
          "type" => "message",
          "user" => "U061F7AUR",
          "text" => "How many cats did we herd yesterday?",
          "ts" => "1593500393.002100",
          "channel" => "C061EG9SL",
          "event_ts" => "1593500393.002100",
          "channel_type" => "channel"
        }
      }

      event = Payload.new(payload)
      assert event.type == "message"
      assert event.user_id == "U061F7AUR"
      assert event.text == "How many cats did we herd yesterday?"
      assert event.ts == "1593500393.002100"
      assert event.channel_id == "C061EG9SL"
    end

    test "uses event_ts when ts is not present" do
      payload = %{
        "event" => %{
          "type" => "app_home_opened",
          "event_ts" => "1515449522000016"
        }
      }

      event = Payload.new(payload)
      assert event.ts == "1515449522000016"
    end
  end

  describe "new/1 with command payload" do
    test "creates Command struct from slash command payload" do
      payload = %{
        "command" => "/weather",
        "text" => "94070",
        "response_url" => "https://hooks.slack.com/commands/1234/5678",
        "trigger_id" => "13345224609.738474920.8088930838d88f008e0",
        "user_id" => "U2147483697",
        "user_name" => "Steve",
        "team_id" => "T0001",
        "team_domain" => "example",
        "channel_id" => "C2147483705",
        "channel_name" => "test",
        "api_app_id" => "A123456"
      }

      assert %Payload.Command{} = command = Payload.new(payload)
      assert command.command == "/weather"
      assert command.text == "94070"
      assert command.user_id == "U2147483697"
      assert command.user_name == "Steve"
      assert command.channel_id == "C2147483705"
      assert command.channel_name == "test"
      assert command.team_id == "T0001"
      assert command.team_domain == "example"
      assert command.response_url == "https://hooks.slack.com/commands/1234/5678"
      assert command.trigger_id == "13345224609.738474920.8088930838d88f008e0"
    end

    test "defaults text to empty string when not present" do
      payload = %{
        "command" => "/weather",
        "user_id" => "U2147483697",
        "team_id" => "T0001"
      }

      command = Payload.new(payload)
      assert command.text == ""
    end
  end

  describe "new/1 with action payload" do
    test "creates Action struct from block_actions payload with button" do
      payload = %{
        "type" => "block_actions",
        "user" => %{
          "id" => "U123ABC456",
          "username" => "spengler",
          "name" => "spengler",
          "team_id" => "T123ABC456"
        },
        "api_app_id" => "A123ABC456",
        "token" => "verification_token",
        "container" => %{
          "type" => "message",
          "message_ts" => "1548261231.000200",
          "channel_id" => "C123ABC456",
          "is_ephemeral" => false
        },
        "trigger_id" => "123456.789.abc",
        "team" => %{
          "id" => "T123ABC456",
          "domain" => "coverbands"
        },
        "channel" => %{
          "id" => "C123ABC456",
          "name" => "general"
        },
        "message" => %{
          "type" => "message",
          "user" => "U123ABC456",
          "ts" => "1548261231.000200",
          "text" => "Click the button"
        },
        "response_url" => "https://hooks.slack.com/actions/T123ABC456/1234567890/abcdefg",
        "actions" => [
          %{
            "type" => "button",
            "action_id" => "approve_button",
            "block_id" => "approval_block",
            "text" => %{
              "type" => "plain_text",
              "text" => "Approve",
              "emoji" => true
            },
            "value" => "approve",
            "style" => "primary",
            "action_ts" => "1548426417.840180"
          }
        ]
      }

      assert %Payload.Action{} = action = Payload.new(payload)
      assert action.type == "block_actions"
      assert action.user_id == "U123ABC456"
      assert action.channel_id == "C123ABC456"
      assert action.trigger_id == "123456.789.abc"
      assert action.container["type"] == "message"
      assert action.container["message_ts"] == "1548261231.000200"

      assert %Payload.Action.ButtonAction{} = button = action.action
      assert button.type == "button"
      assert button.action_id == "approve_button"
      assert button.block_id == "approval_block"
      assert button.action_ts == "1548426417.840180"
      assert button.value == "approve"
      assert button.text["text"] == "Approve"
    end

    test "creates Action struct from modal view submission" do
      payload = %{
        "type" => "block_actions",
        "user" => %{
          "id" => "U123ABC456",
          "username" => "spengler",
          "name" => "spengler",
          "team_id" => "T123ABC456"
        },
        "api_app_id" => "A123ABC456",
        "token" => "verification_token",
        "container" => %{
          "type" => "view",
          "view_id" => "V123ABC456"
        },
        "trigger_id" => "123456.789.abc",
        "team" => %{
          "id" => "T123ABC456",
          "domain" => "coverbands"
        },
        "view" => %{
          "id" => "V123ABC456",
          "team_id" => "T123ABC456",
          "type" => "modal",
          "title" => %{
            "type" => "plain_text",
            "text" => "My Modal"
          },
          "blocks" => [
            %{
              "type" => "section",
              "text" => %{
                "type" => "mrkdwn",
                "text" => "Choose an option"
              }
            }
          ],
          "close" => %{
            "type" => "plain_text",
            "text" => "Cancel"
          },
          "submit" => %{
            "type" => "plain_text",
            "text" => "Submit"
          },
          "state" => %{
            "values" => %{}
          },
          "hash" => "156663117.cd37c1f1",
          "private_metadata" => "",
          "callback_id" => "view_identifier",
          "root_view_id" => "V123ABC456",
          "app_id" => "A123ABC456",
          "bot_id" => "B123ABC456"
        },
        "actions" => [
          %{
            "type" => "button",
            "action_id" => "modal_button",
            "block_id" => "modal_block",
            "text" => %{
              "type" => "plain_text",
              "text" => "Click Me"
            },
            "action_ts" => "1548426417.840180"
          }
        ]
      }

      action = Payload.new(payload)
      assert action.channel_id == nil
      assert action.view["type"] == "modal"
      assert action.view["callback_id"] == "view_identifier"
      assert action.container["type"] == "view"
    end
  end
end
