defmodule Boltex.Client do
  @moduledoc """
  Slack Web API client facade.

  Delegates to a configurable adapter (real API implementation or mock).

  ## Example
      client = Boltex.Client.new(bot_token)

      Boltex.Client.chat_post_message(client, "C1234567890", %{
        text: "Hello!",
        blocks: [%{type: "section", text: %{type: "mrkdwn", text: "Hello!"}}]
      })
  """

  defp adapter do
    Boltex.config()[:client_adapter] || Boltex.Client.Api
  end

  defmodule ApiError do
    @moduledoc """
    Represents a Slack API error response.

    See: https://api.slack.com/web#errors
    """

    @type t :: %__MODULE__{
            error: String.t(),
            messages: [String.t()],
            warnings: [String.t()] | nil,
            request: %{method: atom(), url: String.t(), body: any()}
          }

    defstruct [:error, :messages, :warnings, :request]

    @doc """
    Creates an ApiError from a Slack API error response.
    """
    def from_request(%Tesla.Env{} = env) do
      %__MODULE__{
        error: env.body["error"],
        messages: get_in(env.body, ["response_metadata", "messages"]) || [],
        warnings: get_in(env.body, ["response_metadata", "warnings"]),
        request: %{
          method: env.method,
          url: get_in(env.opts, [:req_url]),
          body: get_in(env.opts, [:req_body])
        }
      }
    end
  end

  defimpl String.Chars, for: ApiError do
    def to_string(%ApiError{} = error) do
      messages_info =
        if error.messages != [], do: ": #{Enum.join(error.messages, ", ")}", else: ""

      """
      Slack API error: #{error.error}#{messages_info}
      --- Request Info:
      #{error.request.body}
      """
    end
  end

  defstruct [:token, :base_url]

  @type t :: %__MODULE__{
          token: String.t(),
          base_url: String.t()
        }

  def new(token) do
    %__MODULE__{
      token: token,
      base_url: "https://slack.com/api"
    }
  end

  @doc """
  Post a message to a channel.

  https://docs.slack.dev/reference/methods/chat.postMessage

  ## Arguments
  - `channel` - Slack channel ID (required)
  - `arguments` - Map of arguments (e.g., `%{text: "Hello", blocks: [...], thread_ts: "..."}`)
  """
  def chat_post_message(client, channel, arguments \\ %{}) do
    adapter().chat_post_message(client, channel, arguments)
  end

  @doc """
  Update a message.

  https://docs.slack.dev/reference/methods/chat.update

  ## Arguments
  - `channel` - Slack channel ID (required)
  - `ts` - Message timestamp to update (required)
  - `arguments` - Map of arguments (e.g., `%{text: "Updated", blocks: [...]}`)
  """
  def chat_update(client, channel, ts, arguments \\ %{}) do
    adapter().chat_update(client, channel, ts, arguments)
  end

  @doc """
  Publish a view to App Home.

  https://docs.slack.dev/reference/methods/views.publish

  ## Arguments
  - `user_id` - User ID to publish view for (required)
  - `view` - View payload (required)
  - `arguments` - Map of additional arguments
  """
  def views_publish(client, user_id, view, arguments \\ %{}) do
    adapter().views_publish(client, user_id, view, arguments)
  end

  @doc """
  Open a modal view.

  https://docs.slack.dev/reference/methods/views.open

  ## Arguments
  - `trigger_id` - Trigger ID from an interaction (required, must be used within 3 seconds)
  - `view` - Modal view payload (required)
  - `arguments` - Map of additional arguments
  """
  def views_open(client, trigger_id, view, arguments \\ %{}) do
    adapter().views_open(client, trigger_id, view, arguments)
  end

  @doc """
  Get information about a user.

  https://docs.slack.dev/reference/methods/users.info

  ## Arguments
  - `user_id` - User ID (required)
  - `arguments` - Map of additional arguments
  """
  def users_info(client, user_id, arguments \\ %{}) do
    adapter().users_info(client, user_id, arguments)
  end

  @doc """
  Find a user by email address.

  https://docs.slack.dev/reference/methods/users.lookupByEmail

  ## Arguments
  - `email` - Email address (required)
  """
  def users_lookup_by_email(client, email) do
    adapter().users_lookup_by_email(client, email)
  end

  @doc """
  Join a public channel.

  https://api.slack.com/methods/conversations.join

  ## Arguments
  - `channel` - Channel ID (required)
  - `arguments` - Map of additional arguments
  """
  def conversations_join(client, channel, arguments \\ %{}) do
    adapter().conversations_join(client, channel, arguments)
  end

  @doc """
  List conversations the bot is a member of.

  https://api.slack.com/methods/conversations.list

  ## Arguments
  - `arguments` - Map of arguments (e.g., `%{types: "public_channel,private_channel"}`)
  """
  def conversations_list(client, arguments \\ %{}) do
    adapter().conversations_list(client, arguments)
  end
end
