defmodule Boltex.Events.Middleware do
  @moduledoc """
  Behaviour for context middleware.

  Middleware can transform the context before it reaches handlers,
  adding app-specific data like org associations, user preferences, etc.

  ## Example
      defmodule MyApp.Slack.Middleware.Logger do
        @behaviour Boltex.Events.Middleware

        require Logger

        def call(ctx, event, _opts) do
          Logger.info("Slack event: \#{inspect(event)} from team \#{ctx.team_id}")
          {:ok, ctx}
        end
      end
  """

  @callback call(
              ctx :: Boltex.Events.Context.t(),
              event :: Boltex.Events.Payload.t(),
              opts :: keyword()
            ) :: {:ok, Boltex.Events.Context.t()} | {:halt, term()}
end
