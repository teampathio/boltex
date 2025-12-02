defmodule Boltex.Async do
  @moduledoc """
  Async wrapper for Boltex client functions.

  All functions run under `Boltex.TaskSupervisor`, ensuring tasks are properly
  supervised and isolated - one failure won't affect others.

  ## Example

      # Fire and forget
      Boltex.Async.call(fn ->
        Boltex.Client.chat_post_message(client, channel_id, blocks, text: "Hello!")
      end)

      # Wait for result
      task = Boltex.Async.call(fn ->
        Boltex.Client.chat_post_message(client, channel_id, blocks, text: "Hello!")
      end)
      result = Task.await(task)
  """

  @doc """
  Execute a function asynchronously under Boltex.TaskSupervisor.

  Returns a `Task` that can be awaited or ignored.

  In test mode, runs synchronously to avoid DB connection ownership issues.
  """
  if Mix.env() == :test do
    def call(fun) when is_function(fun, 0) do
      fun.()
      %Task{ref: make_ref(), pid: self(), owner: self(), mfa: {__MODULE__, :call, [fun]}}
    end
  else
    def call(fun) when is_function(fun, 0) do
      Task.Supervisor.async_nolink(Boltex.TaskSupervisor, fun)
    end
  end
end
