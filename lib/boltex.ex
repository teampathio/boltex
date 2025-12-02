defmodule Boltex do
  @moduledoc """
  Boltex is an unofficial Elixir library for building Slack apps.

  Inspired by (but not affiliated with) Slack's official Bolt frameworks
  for Python and TypeScript.

  ## Features

  - Event handling with middleware pipeline
  - OAuth flow support with `Boltex.OAuthController`
  - Slack Web API client via `Boltex.Client`
  - Installation management with Ecto via `Boltex.Installations`
  - Block Kit helpers in `Boltex.Blocks`
  - Action helpers in `Boltex.Actions`

  ## Configuration

  Required configuration in `config.exs`:

      config :boltex,
        repo: MyApp.Repo,
        client_id: "YOUR_CLIENT_ID",
        client_secret: "YOUR_CLIENT_SECRET",
        signing_secret: "YOUR_SIGNING_SECRET",
        scopes: "chat:write,app_mentions:read,channels:read"

  ## Example App Module

      defmodule MyApp.Slack do
        use Boltex.App

        middleware MyApp.Slack.Middleware.Logger
        handler MyApp.Slack.Handlers.Events

        @impl true
        def handle_install_success(conn, installation, metadata) do
          conn
          |> put_flash(:info, "Slack app installed successfully!")
          |> redirect(to: "/")
        end

        @impl true
        def handle_install_failure(conn, error) do
          conn
          |> put_flash(:error, "Installation failed")
          |> redirect(to: "/")
        end
      end

  The app module must be accessible via `conn.assigns[:boltex_app]` or
  `conn.private[:boltex_app]` when controllers are invoked.

  See `Boltex.App`, `Boltex.OAuthController`, and `Boltex.EventsController`
  for details on routing and integration.
  """

  def config do
    Application.get_all_env(:boltex)
  end
end
