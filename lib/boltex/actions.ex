defmodule Boltex.Actions do
  @moduledoc """
  Actions for responding to Slack events.

  Import this in your handlers for ergonomic APIs.

  ## Example
      defmodule MyApp.Slack.Handlers.Home do
        import Boltex.Actions

        def handle_event(ctx, _event) do
          say(ctx, [%{type: "section", text: %{type: "mrkdwn", text: "Hello!"}}])
        end
      end
  """

  alias Boltex.Client
  alias Boltex.Events.Context

  @doc """
  Acknowledge an interactive event (button click, slash command, etc).

  Must be returned from `handle_sync/2` to acknowledge receipt within 3 seconds.

  ## Arguments
  - No arguments: Returns empty response body (HTTP 200 with no content)
  - String: Returns a simple text response visible to the user

  ## Examples
      # Empty acknowledgment (no visible response)
      def handle_sync(%Action{}, ctx) do
        ack()
      end

      # Simple text response
      def handle_sync(%Command{}, ctx) do
        ack("Got it!")
      end
  """
  def ack(), do: {:ok, ""}
  def ack(text) when is_binary(text), do: {:ok, %{text: text}}

  @doc """
  Send a message to the event's channel.

  ## Example
      say(ctx, %{text: "Hello!"})
      say(ctx, %{blocks: [...], text: "Hello!"})
  """
  def say(%Context{} = ctx, arguments \\ %{}) do
    Client.chat_post_message(ctx.client, ctx.channel_id, arguments)
  end

  @doc """
  Publish a view to App Home for the event's user.
  """
  def publish_home(%Context{} = ctx, view) do
    Client.views_publish(ctx.client, ctx.user_id, view)
  end

  @doc """
  Open a modal view.

  Must be called with a trigger_id from an interactive payload (button click, etc).
  The trigger_id expires after 3 seconds.

  ## Example
      def handle_sync(%Action{action: %{action_id: "open_form"}} = action, ctx) do
        view = %{
          type: "modal",
          callback_id: "form_submission",
          title: %{type: "plain_text", text: "My Form"},
          submit: %{type: "plain_text", text: "Submit"},
          blocks: [...]
        }
        open_modal(ctx, action.trigger_id, view)
        ack()
      end
  """
  def open_modal(%Context{} = ctx, trigger_id, view) do
    Client.views_open(ctx.client, trigger_id, view)
  end

  @doc """
  Reply in a thread.
  """
  def reply(%Context{} = ctx, %{ts: thread_ts}, arguments \\ %{}) when not is_nil(thread_ts) do
    arguments = Map.put(arguments, :thread_ts, thread_ts)
    say(ctx, arguments)
  end
end
