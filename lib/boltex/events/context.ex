defmodule Boltex.Events.Context do
  @moduledoc """
  Context object passed to event listeners.

  Pure data structure - no business logic here.
  Use Boltex.Actions for convenience functions.
  """

  @type t :: %__MODULE__{
          team_id: String.t(),
          user_id: String.t() | nil,
          channel_id: String.t() | nil,
          bot_token: String.t(),
          client: Boltex.Client.t(),
          assigns: map(),
          halted: boolean()
        }

  defstruct [
    :team_id,
    :user_id,
    :channel_id,
    :bot_token,
    :client,
    assigns: %{},
    halted: false
  ]

  @doc """
  Assign a value to the context.
  """
  def assign(%__MODULE__{} = context, key, value) do
    %{context | assigns: Map.put(context.assigns, key, value)}
  end

  @doc """
  Halt middleware pipeline processing.
  """
  def halt(%__MODULE__{} = context) do
    %{context | halted: true}
  end
end
