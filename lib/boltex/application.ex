defmodule Boltex.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Boltex.Supervisor
    ]

    opts = [strategy: :one_for_one, name: Boltex.ApplicationSupervisor]
    Supervisor.start_link(children, opts)
  end
end
