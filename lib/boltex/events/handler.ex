defmodule Boltex.Events.Handler do
  @moduledoc """
  Behaviour for handling Slack events.

  All events must be acknowledged within 3 seconds. Use `handle_sync/2` for
  interactive payloads that can include a response body, and `handle_async/2` for
  event callbacks that cannot.

  ## `handle_sync/2` - Interactive Payloads

  Slash commands, block actions, shortcuts, and view submissions.
  Can return response content in acknowledgment.

  Return values:
  - `:ignore` - Handler doesn't handle this event, continue to next handler
  - `{:ok, response}` - Return this response body (halts handler chain)
  - `{:error, reason}` - Handler failed (halts handler chain)

  If multiple handlers return `{:ok, response}` for the same event, an error
  will be raised. Each handler should return `:ignore` for events it doesn't handle.

      defmodule MyApp.Slack.Handlers.Commands do
        @behaviour Boltex.Events.Handler

        alias Boltex.Events.Payload.Command

        @impl true
        def handle_sync(%Command{command: "/help"}, _ctx) do
          {:ok, %{
            response_type: "ephemeral",
            text: "Here's how to use this app..."
          }}
        end

        def handle_sync(_event, _ctx), do: :ignore
      end

  ## `handle_async/2` - Event Callbacks

  Events API callbacks like `app_home_opened`, `message`, `app_mention`, etc.
  Must acknowledge immediately, cannot return response content.

  Handlers run under `Boltex.TaskSupervisor` to isolate failures. Crashes won't
  take down your app, but failed handlers are not retried. For retry guarantees,
  use a job queue (e.g., Oban).

      defmodule MyApp.Slack.Handlers.Home do
        @behaviour Boltex.Events.Handler

        import Boltex.Actions
        alias Boltex.Events.Payload.Event

        @impl true
        def handle_async(%Event{type: "app_home_opened"}, ctx) do
          view = build_home_view(ctx)
          publish_home(ctx, view)
          :ok
        end

        def handle_async(_event, _ctx), do: :ok
      end
  """

  @callback handle_sync(
              event :: Boltex.Events.Payload.t(),
              ctx :: Boltex.Events.Context.t()
            ) :: :ignore | {:ok, map()} | {:error, term()}

  @callback handle_async(
              event :: Boltex.Events.Payload.t(),
              ctx :: Boltex.Events.Context.t()
            ) :: :ok | {:error, term()}

  @optional_callbacks [handle_sync: 2, handle_async: 2]
end
