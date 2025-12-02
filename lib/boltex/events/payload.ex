defmodule Boltex.Events.Payload do
  @moduledoc """
  Structured payloads for Slack events.
  """

  @type t ::
          __MODULE__.Event.t()
          | __MODULE__.Command.t()
          | __MODULE__.Action.t()
          | __MODULE__.ViewSubmit.t()

  def new(%{"event" => event_data}), do: __MODULE__.Event.new(event_data)
  def new(%{"command" => _} = command_data), do: __MODULE__.Command.new(command_data)
  def new(%{"type" => "block_actions"} = action_data), do: __MODULE__.Action.new(action_data)
  def new(%{"type" => "view_submission"} = view_data), do: __MODULE__.ViewSubmit.new(view_data)

  defmodule Event do
    @moduledoc """
    Represents a Slack Events API event.

    Background notifications from Slack (app_home_opened, message, etc).

    See: https://api.slack.com/events-api
    """

    @type t :: %__MODULE__{
            type: String.t(),
            user_id: String.t() | nil,
            channel_id: String.t() | nil,
            ts: String.t() | nil,
            tab: String.t() | nil,
            view: map() | nil,
            text: String.t() | nil
          }

    defstruct [
      :type,
      :user_id,
      :channel_id,
      :ts,
      :tab,
      :view,
      :text
    ]

    def new(event_data) when is_map(event_data) do
      %__MODULE__{
        type: event_data["type"],
        user_id: event_data["user"],
        channel_id: event_data["channel"],
        ts: event_data["ts"] || event_data["event_ts"],
        tab: event_data["tab"],
        view: event_data["view"],
        text: event_data["text"]
      }
    end
  end

  defmodule Command do
    @moduledoc """
    Represents a Slack slash command.

    Interactive commands triggered by users (/teampath help, etc).

    See: https://api.slack.com/interactivity/slash-commands
    """

    @type t :: %__MODULE__{
            command: String.t(),
            text: String.t(),
            user_id: String.t(),
            user_name: String.t(),
            channel_id: String.t(),
            channel_name: String.t(),
            team_id: String.t(),
            team_domain: String.t(),
            response_url: String.t(),
            trigger_id: String.t()
          }

    defstruct [
      :command,
      :text,
      :user_id,
      :user_name,
      :channel_id,
      :channel_name,
      :team_id,
      :team_domain,
      :response_url,
      :trigger_id
    ]

    def new(command_data) when is_map(command_data) do
      %__MODULE__{
        command: command_data["command"],
        text: command_data["text"] || "",
        user_id: command_data["user_id"],
        user_name: command_data["user_name"],
        channel_id: command_data["channel_id"],
        channel_name: command_data["channel_name"],
        team_id: command_data["team_id"],
        team_domain: command_data["team_domain"],
        response_url: command_data["response_url"],
        trigger_id: command_data["trigger_id"]
      }
    end
  end

  defmodule Action do
    @moduledoc """
    Represents a Slack block_actions interaction.

    Interactive components like buttons, selects, etc.

    See: https://api.slack.com/reference/interaction-payloads/block-actions
    """

    alias __MODULE__.ButtonAction

    # TODO: Add other action types to this union as they're implemented
    @type action_element :: ButtonAction.t()

    @type t :: %__MODULE__{
            type: String.t(),
            user_id: String.t(),
            channel_id: String.t() | nil,
            action: action_element(),
            trigger_id: String.t(),
            container: map(),
            view: map() | nil
          }

    defstruct [
      :type,
      :user_id,
      :channel_id,
      :action,
      :trigger_id,
      :container,
      :view
    ]

    def new(action_data) when is_map(action_data) do
      # Extract the single action from the actions array
      # (Slack always sends exactly one action per interaction)
      raw_action = List.first(action_data["actions"] || [])

      %__MODULE__{
        type: action_data["type"],
        user_id: get_in(action_data, ["user", "id"]),
        channel_id: get_in(action_data, ["channel", "id"]),
        action: parse_action(raw_action),
        trigger_id: action_data["trigger_id"],
        container: action_data["container"],
        view: action_data["view"]
      }
    end

    defp parse_action(%{"type" => "button"} = action_data) do
      ButtonAction.new(action_data)
    end

    # TODO: Add parsers for other action types:
    # - StaticSelectAction (static_select)
    # - UsersSelectAction (users_select)
    # - ConversationsSelectAction (conversations_select)
    # - ChannelsSelectAction (channels_select)
    # - ExternalSelectAction (external_select)
    # - MultiStaticSelectAction (multi_static_select)
    # - MultiUsersSelectAction (multi_users_select)
    # - MultiConversationsSelectAction (multi_conversations_select)
    # - MultiChannelsSelectAction (multi_channels_select)
    # - MultiExternalSelectAction (multi_external_select)
    # - OverflowAction (overflow)
    # - DatepickerAction (datepicker)
    # - TimepickerAction (timepicker)
    # - RadioButtonsAction (radio_buttons)
    # - CheckboxesAction (checkboxes)
    # - PlainTextInputAction (plain_text_input)
    # - RichTextInputAction (rich_text_input)

    defmodule ButtonAction do
      @moduledoc """
      Represents a button element action.

      See: https://api.slack.com/reference/block-kit/block-elements#button
      """

      @type t :: %__MODULE__{
              type: String.t(),
              action_id: String.t(),
              block_id: String.t(),
              action_ts: String.t(),
              value: String.t() | nil,
              text: map(),
              url: String.t() | nil
            }

      defstruct [
        :type,
        :action_id,
        :block_id,
        :action_ts,
        :value,
        :text,
        :url
      ]

      def new(action_data) when is_map(action_data) do
        %__MODULE__{
          type: action_data["type"],
          action_id: action_data["action_id"],
          block_id: action_data["block_id"],
          action_ts: action_data["action_ts"],
          value: action_data["value"],
          text: action_data["text"],
          url: action_data["url"]
        }
      end
    end
  end

  defmodule ViewSubmit do
    @moduledoc """
    Represents a Slack view_submission interaction.

    Triggered when a user submits a modal view.

    See: https://api.slack.com/reference/interaction-payloads/views
    """

    @type t :: %__MODULE__{
            type: String.t(),
            user_id: String.t(),
            team_id: String.t(),
            callback_id: String.t(),
            view: map(),
            form: map(),
            trigger_id: String.t(),
            response_urls: list()
          }

    defstruct [
      :type,
      :user_id,
      :team_id,
      :callback_id,
      :view,
      :form,
      :trigger_id,
      :response_urls
    ]

    def new(view_data) when is_map(view_data) do
      view = view_data["view"]

      %__MODULE__{
        type: view_data["type"],
        user_id: get_in(view_data, ["user", "id"]),
        team_id: view_data["team_id"],
        callback_id: view["callback_id"],
        view: view,
        form: extract_form_values(view),
        trigger_id: view_data["trigger_id"],
        response_urls: view_data["response_urls"] || []
      }
    end

    defp extract_form_values(view) do
      state_values = get_in(view, ["state", "values"]) || %{}

      for {_block_id, block_values} <- state_values,
          {action_id, field_data} <- block_values,
          into: %{} do
        value = extract_field_value(field_data)
        {action_id, value}
      end
    end

    defp extract_field_value(%{"type" => "plain_text_input", "value" => value}), do: value
    defp extract_field_value(%{"type" => "users_select", "selected_user" => user}), do: user

    defp extract_field_value(%{
           "type" => "conversations_select",
           "selected_conversation" => conversation
         }),
         do: conversation

    defp extract_field_value(%{
           "type" => "static_select",
           "selected_option" => %{"value" => value}
         }),
         do: value

    defp extract_field_value(%{"type" => "multi_users_select", "selected_users" => users}),
      do: users

    defp extract_field_value(%{
           "type" => "multi_conversations_select",
           "selected_conversations" => conversations
         }),
         do: conversations

    defp extract_field_value(%{"type" => "multi_static_select", "selected_options" => options}),
      do: Enum.map(options, & &1["value"])

    defp extract_field_value(%{"type" => "checkboxes", "selected_options" => options}),
      do: Enum.map(options, & &1["value"])

    defp extract_field_value(%{
           "type" => "radio_buttons",
           "selected_option" => %{"value" => value}
         }),
         do: value

    defp extract_field_value(%{"type" => "datepicker", "selected_date" => date}), do: date
    defp extract_field_value(%{"type" => "timepicker", "selected_time" => time}), do: time
    defp extract_field_value(_), do: nil
  end
end
