defmodule Boltex.SlackInstallation do
  @moduledoc """
  Ecto schema for Slack workspace installations.

  Stores the OAuth tokens and metadata when a workspace installs your Slack app.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  schema "boltex_slack_installations" do
    field :team_id, :string
    field :team_name, :string
    field :bot_token, :string
    field :bot_user_id, :string
    field :scope, :string
    field :authed_user, :map
    field :enterprise_id, :string
    field :is_enterprise_install, :boolean, default: false

    timestamps(type: :utc_datetime)
  end

  @doc false
  def create_changeset(installation, attrs) do
    installation
    |> cast(attrs, [
      :team_id,
      :team_name,
      :bot_token,
      :bot_user_id,
      :scope,
      :authed_user,
      :enterprise_id,
      :is_enterprise_install
    ])
    |> validate_required([
      :team_id,
      :team_name,
      :bot_token,
      :bot_user_id,
      :scope,
      :authed_user
    ])
    |> unique_constraint(:team_id)
  end

  @doc false
  def update_changeset(installation, attrs) do
    installation
    |> cast(attrs, [:scope, :bot_token])
    |> validate_required([:scope, :bot_token])
  end
end
