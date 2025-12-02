defmodule Boltex.Repo do
  @moduledoc """
  Behavior defining the repository interface used by Boltex.

  Your application's Ecto.Repo already implements these callbacks.
  """

  @callback get_by(queryable :: Ecto.Queryable.t(), clauses :: keyword() | map()) ::
              Ecto.Schema.t() | nil

  @callback insert(struct_or_changeset :: Ecto.Schema.t() | Ecto.Changeset.t()) ::
              {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}

  @callback update(changeset :: Ecto.Changeset.t()) ::
              {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}

  @callback delete_all(queryable :: Ecto.Queryable.t()) :: {non_neg_integer(), nil | [term()]}

  @callback one(queryable :: Ecto.Queryable.t()) :: Ecto.Schema.t() | nil

  @callback all(queryable :: Ecto.Queryable.t()) :: [Ecto.Schema.t()]
end
