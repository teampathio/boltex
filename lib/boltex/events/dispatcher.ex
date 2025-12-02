defmodule Boltex.Events.Dispatcher do
  @moduledoc """
  Routes events to registered listeners after running middleware pipeline.

  Reads middleware and handlers from the configured Boltex.App module.

  All handlers must implement both `handle_sync/2` and `handle_async/2`. Handlers
  can skip events by returning `:ignore` or `:ok` respectively.
  """

  require Logger

  @doc """
  Dispatch an event to handlers.

  ## Modes
  - `:sync` - Runs synchronously, can return response body (slash commands, actions, etc.)
  - `:async` - Runs asynchronously under TaskSupervisor (event callbacks)
  """
  def dispatch(event, ctx, app_module, :sync) do
    result =
      ctx
      |> run_middleware(event, app_module)
      |> run_sync_handlers(event, app_module)

    case result do
      :ignore ->
        event_id = get_event_identifier(event)

        raise Boltex.Error, """
        Sync event #{inspect(event_id)} was not handled by any handler.

        Sync events (block_actions, slash commands, view submissions) must be handled by exactly one handler.

        Add a handler that implements handle_sync/2 and returns {:ok, response} for this event type.
        """

      other ->
        other
    end
  end

  def dispatch(event, ctx, app_module, :async) do
    Boltex.Async.call(fn ->
      ctx
      |> run_middleware(event, app_module)
      |> run_async_handlers(event, app_module)
    end)

    :ok
  end

  defp run_middleware(ctx, event, app_module) do
    middleware = app_module.middleware()

    Enum.reduce_while(middleware, ctx, fn
      _middleware_module, %{halted: true} = acc ->
        {:halt, acc}

      middleware_module, acc ->
        case apply(middleware_module, :call, [acc, event, []]) do
          {:ok, new_ctx} ->
            {:cont, new_ctx}

          {:halt, reason} ->
            Logger.info("Middleware #{inspect(middleware_module)} halted: #{inspect(reason)}")
            {:halt, %{acc | halted: true}}

          error ->
            Logger.error("""
            Middleware #{inspect(middleware_module)} returned invalid response:
            #{inspect(error)}
            """)

            {:cont, acc}
        end
    end)
  end

  defp run_sync_handlers(ctx, event, app_module) do
    run_handlers(ctx, event, app_module, :handle_sync)
  end

  defp run_async_handlers(ctx, event, app_module) do
    run_handlers(ctx, event, app_module, :handle_async)
  end

  defp run_handlers(%{halted: true} = _ctx, _event, _app_module, _callback_name) do
    Logger.debug("Handler execution skipped - middleware halted")
    :ok
  end

  defp run_handlers(ctx, event, app_module, callback_name) do
    handlers = app_module.event_handlers()

    Enum.reduce_while(handlers, :ignore, fn handler_module, acc ->
      try do
        case apply(handler_module, callback_name, [event, ctx]) do
          :ignore ->
            {:cont, acc}

          :ok ->
            {:cont, acc}

          {:ok, response} when acc == :ignore ->
            {:halt, {:ok, response}}

          {:ok, _response} ->
            raise Boltex.Error, """
            Multiple handlers returned a sync response for event: #{inspect(event.type)}

            Only one handler should respond to sync events (block_actions, slash commands, view submissions).

            Ensure only one handler returns {:ok, response} for this event type.
            """

          {:error, _reason} = error ->
            {:halt, error}
        end
      rescue
        e in UndefinedFunctionError ->
          Logger.error("""
          Handler #{inspect(handler_module)} does not implement #{callback_name}/2:
          #{Exception.message(e)}
          """)

          {:cont, acc}

        e ->
          Logger.error("""
          Event handler #{inspect(handler_module)}.#{callback_name}/2 failed:
          #{Exception.format(:error, e, __STACKTRACE__)}
          """)

          {:cont, acc}
      end
    end)
  end

  defp get_event_identifier(%Boltex.Events.Payload.Action{action: action}), do: action.action_id
  defp get_event_identifier(%Boltex.Events.Payload.Command{command: command}), do: command
  defp get_event_identifier(%Boltex.Events.Payload.Event{type: type}), do: type

  defp get_event_identifier(%Boltex.Events.Payload.ViewSubmit{callback_id: callback_id}),
    do: callback_id
end
