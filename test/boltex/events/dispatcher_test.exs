defmodule Boltex.Events.DispatcherTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias Boltex.Events.Context
  alias Boltex.Events.Dispatcher
  alias Boltex.Events.Payload

  defmodule TestApp do
    def middleware, do: []
    def event_handlers, do: []
  end

  defmodule TestMiddleware do
    def call(ctx, _event, _opts), do: {:ok, Context.assign(ctx, :middleware_called, true)}
  end

  defmodule HaltingMiddleware do
    def call(_ctx, _event, _opts), do: {:halt, "stopped"}
  end

  defmodule InvalidMiddleware do
    def call(_ctx, _event, _opts), do: :invalid_return
  end

  defmodule IgnoreHandler do
    def handle_sync(_event, _ctx), do: :ignore
    def handle_async(_event, _ctx), do: :ignore
  end

  defmodule RespondingHandler do
    def handle_sync(_event, _ctx), do: {:ok, %{text: "response"}}
    def handle_async(_event, _ctx), do: :ok
  end

  defmodule SecondRespondingHandler do
    def handle_sync(_event, _ctx), do: {:ok, %{text: "second response"}}
    def handle_async(_event, _ctx), do: :ok
  end

  defmodule ErrorHandler do
    def handle_sync(_event, _ctx), do: {:error, :something_failed}
    def handle_async(_event, _ctx), do: {:error, :something_failed}
  end

  defmodule RaisingHandler do
    def handle_sync(_event, _ctx), do: raise("boom")
    def handle_async(_event, _ctx), do: raise("boom")
  end

  defmodule MissingCallbackHandler do
  end

  setup do
    ctx = %Context{
      team_id: "T123",
      user_id: "U123",
      channel_id: "C123",
      bot_token: "xoxb-token",
      client: Boltex.Client.new("xoxb-token"),
      assigns: %{},
      halted: false
    }

    event = %Payload.Event{
      type: "message",
      user_id: "U123",
      channel_id: "C123",
      text: "test",
      ts: "1234567890.123456"
    }

    {:ok, ctx: ctx, event: event}
  end

  describe "dispatch/4 sync" do
    test "raises when no handler responds to sync event", %{ctx: ctx, event: event} do
      app = Module.concat(__MODULE__, NoHandlerApp)

      defmodule app do
        def middleware, do: []
        def event_handlers, do: [IgnoreHandler]
      end

      assert_raise Boltex.Error, ~r/was not handled by any handler/, fn ->
        Dispatcher.dispatch(event, ctx, app, :sync)
      end
    end

    test "returns response when handler responds", %{ctx: ctx, event: event} do
      app = Module.concat(__MODULE__, RespondingApp)

      defmodule app do
        def middleware, do: []
        def event_handlers, do: [RespondingHandler]
      end

      assert {:ok, %{text: "response"}} = Dispatcher.dispatch(event, ctx, app, :sync)
    end

    test "first responding handler wins", %{ctx: ctx, event: event} do
      app = Module.concat(__MODULE__, MultiHandlerApp)

      defmodule app do
        def middleware, do: []
        def event_handlers, do: [RespondingHandler, RespondingHandler]
      end

      assert {:ok, %{text: "response"}} = Dispatcher.dispatch(event, ctx, app, :sync)
    end

    test "runs middleware before handlers", %{ctx: ctx, event: event} do
      app = Module.concat(__MODULE__, MiddlewareApp)

      defmodule app do
        def middleware, do: [TestMiddleware]
        def event_handlers, do: []
      end

      capture_log(fn ->
        assert_raise Boltex.Error, fn ->
          Dispatcher.dispatch(event, ctx, app, :sync)
        end
      end)
    end

    test "halting middleware prevents handler execution", %{ctx: ctx, event: event} do
      app = Module.concat(__MODULE__, HaltedApp)

      defmodule app do
        def middleware, do: [HaltingMiddleware]
        def event_handlers, do: [RespondingHandler]
      end

      log =
        capture_log(fn ->
          assert :ok = Dispatcher.dispatch(event, ctx, app, :sync)
        end)

      assert log =~ "halted"
    end

    test "returns error response from handler", %{ctx: ctx, event: event} do
      app = Module.concat(__MODULE__, ErrorApp)

      defmodule app do
        def middleware, do: []
        def event_handlers, do: [ErrorHandler]
      end

      assert {:error, :something_failed} = Dispatcher.dispatch(event, ctx, app, :sync)
    end

    test "continues to next handler when one raises", %{ctx: ctx, event: event} do
      app = Module.concat(__MODULE__, RaisingApp)

      defmodule app do
        def middleware, do: []
        def event_handlers, do: [RaisingHandler, RespondingHandler]
      end

      capture_log(fn ->
        assert {:ok, %{text: "response"}} = Dispatcher.dispatch(event, ctx, app, :sync)
      end)
    end

    test "logs error when handler missing callback", %{ctx: ctx, event: event} do
      app = Module.concat(__MODULE__, MissingCallbackApp)

      defmodule app do
        def middleware, do: []
        def event_handlers, do: [MissingCallbackHandler]
      end

      log =
        capture_log(fn ->
          assert_raise Boltex.Error, fn ->
            Dispatcher.dispatch(event, ctx, app, :sync)
          end
        end)

      assert log =~ "does not implement handle_sync/2"
    end

    test "logs error when middleware returns invalid response", %{ctx: ctx, event: event} do
      app = Module.concat(__MODULE__, InvalidMiddlewareApp)

      defmodule app do
        def middleware, do: [InvalidMiddleware]
        def event_handlers, do: [RespondingHandler]
      end

      log =
        capture_log(fn ->
          assert {:ok, %{text: "response"}} = Dispatcher.dispatch(event, ctx, app, :sync)
        end)

      assert log =~ "returned invalid response"
    end
  end

  describe "dispatch/4 async" do
    test "returns :ok immediately", %{ctx: ctx, event: event} do
      app = Module.concat(__MODULE__, AsyncApp)

      defmodule app do
        def middleware, do: []
        def event_handlers, do: [RespondingHandler]
      end

      assert :ok = Dispatcher.dispatch(event, ctx, app, :async)
    end
  end
end
