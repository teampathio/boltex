defmodule Boltex.Callbacks do
  @moduledoc """
  Callbacks for handling OAuth installation events.

  Implement this behaviour to customize how installations are handled.

  ## Example

      defmodule MyApp.SlackHandler do
        @behaviour Boltex.Callbacks

        def handle_install_success(conn, installation) do
          # Associate installation with current user's org
          user = conn.assigns[:current_user]
          MyApp.Orgs.associate_slack(user.org_id, installation.team_id)

          conn
          |> put_flash(:info, "Slack installed for \#{installation.team_name}!")
          |> redirect(to: "/app")
        end

        def handle_install_failure(conn, error) do
          Logger.error("Slack install failed: \#{inspect(error)}")

          conn
          |> put_flash(:error, "Failed to install Slack")
          |> redirect(to: "/settings")
        end
      end

  Then configure:

      config :boltex,
        callbacks: MyApp.SlackHandler

  ## Error Types

  The `handle_install_failure/2` callback will receive one of the following errors:

  - `:invalid_state` - CSRF state parameter validation failed
  - `{:slack_error, error}` - Slack returned an OAuth error (user denied, etc)
  - `{:exchange_failed, reason}` - Failed to exchange code for token (network, invalid response)
  - `{:save_failed, changeset}` - Failed to save installation to database
  - `:invalid_params` - Invalid callback parameters received
  """

  @type installation :: %{
          id: integer(),
          team_id: String.t(),
          team_name: String.t(),
          bot_token: String.t(),
          bot_user_id: String.t(),
          scope: String.t(),
          authed_user: map(),
          enterprise_id: String.t() | nil,
          is_enterprise_install: boolean()
        }

  @type metadata :: %{
          reinstall: boolean(),
          installation_data: map(),
          state: map()
        }

  @type error ::
          :invalid_state
          | {:slack_error, String.t()}
          | {:exchange_failed, term()}
          | {:save_failed, Ecto.Changeset.t()}
          | :invalid_params

  @callback handle_install_success(
              conn :: Plug.Conn.t(),
              installation :: installation(),
              metadata :: metadata()
            ) ::
              Plug.Conn.t()
  @callback handle_install_failure(conn :: Plug.Conn.t(), error :: error()) :: Plug.Conn.t()
end
