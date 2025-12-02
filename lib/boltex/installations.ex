defmodule Boltex.Installations do
  @moduledoc """
  Functions for storing and retrieving Slack installation data.

  When a workspace installs your Slack app, you receive tokens and metadata
  that must be persisted. This module provides functions to manage installations
  in your database using Ecto.

  ## Configuration

  Configure Boltex in config.exs:

      config :boltex,
        repo: MyApp.Repo
  """

  import Ecto.Query
  alias Boltex.SlackInstallation

  @type team_id :: String.t()
  @type installation_params :: %{
          required(:team_id) => String.t(),
          required(:team_name) => String.t(),
          required(:bot_token) => String.t(),
          required(:bot_user_id) => String.t(),
          required(:scope) => String.t(),
          required(:authed_user) => map(),
          optional(:enterprise_id) => String.t() | nil,
          optional(:is_enterprise_install) => boolean()
        }

  @doc """
  Save an installation. Creates a new record or updates an existing one.
  """
  @spec save(installation_params()) :: {:ok, SlackInstallation.t()} | {:error, term()}
  def save(installation) do
    team_id = installation.team_id

    case find(team_id) do
      {:error, :not_found} ->
        %SlackInstallation{}
        |> SlackInstallation.create_changeset(installation)
        |> repo().insert()

      {:ok, existing} ->
        existing
        |> SlackInstallation.update_changeset(installation)
        |> repo().update()
    end
  end

  @doc """
  Find an installation by team_id.
  """
  @spec find(team_id()) :: {:ok, SlackInstallation.t()} | {:error, :not_found}
  def find(team_id) do
    case repo().get_by(SlackInstallation, team_id: team_id) do
      nil -> {:error, :not_found}
      installation -> {:ok, installation}
    end
  end

  @doc """
  Quick lookup to get just the bot token for a team.
  Useful for event handling where you need the token immediately.
  """
  @spec find_bot_token(team_id()) :: {:ok, String.t()} | {:error, :not_found}
  def find_bot_token(team_id) do
    token =
      SlackInstallation
      |> where([i], i.team_id == ^team_id)
      |> select([i], i.bot_token)
      |> limit(1)
      |> repo().one()

    case token do
      nil -> {:error, :not_found}
      token -> {:ok, token}
    end
  end

  @doc """
  Delete an installation (called when app is uninstalled).
  """
  @spec delete(team_id()) :: :ok
  def delete(team_id) do
    SlackInstallation
    |> where([i], i.team_id == ^team_id)
    |> repo().delete_all()

    :ok
  end

  @doc """
  List all installations (useful for admin/debugging).
  """
  @spec list() :: {:ok, [SlackInstallation.t()]}
  def list do
    {:ok, repo().all(SlackInstallation)}
  end

  defp repo do
    Boltex.config()[:repo] ||
      raise "Boltex requires :repo to be configured. Add `config :boltex, repo: MyApp.Repo` to your config.exs"
  end
end
