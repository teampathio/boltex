defmodule Boltex.Error do
  @moduledoc """
  Exception raised when Boltex encounters configuration or usage errors.
  """

  defexception [:message]

  @type t :: %__MODULE__{message: String.t()}
end
