defmodule Boltex.App do
  @moduledoc """
  Behaviour for defining a Slack app.

  ## Example
      defmodule MyApp.Slack do
        use Boltex.App

        middleware MyApp.Slack.Middleware.Logger
        middleware MyApp.Slack.Middleware.Auth

        handler MyApp.Slack.Handlers.Home
        handler MyApp.Slack.Handlers.Commands

        # OAuth callbacks - can implement directly or delegate
        @impl true
        def handle_install_success(conn, installation, metadata) do
          conn
          |> put_flash(:info, "Installed!")
          |> redirect(to: "/app")
        end

        @impl true
        def handle_install_failure(conn, error) do
          conn
          |> put_flash(:error, "Installation failed")
          |> redirect(to: "/")
        end

        # Or delegate to separate module:
        # defdelegate handle_install_success(conn, installation, metadata),
        #   to: MyApp.Slack.Callbacks
      end

  Then mount in your router:
      scope "/slack" do
        pipe_through :browser
        forward "/", Boltex.Plug, app: MyApp.Slack
      end
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
          installation_data: map()
        }

  @type install_error ::
          :invalid_state
          | {:slack_error, String.t()}
          | {:exchange_failed, term()}
          | {:save_failed, Ecto.Changeset.t()}
          | :invalid_params

  @callback middleware() :: [module()]
  @callback event_handlers() :: [module()]
  @callback handle_install_success(
              conn :: Plug.Conn.t(),
              installation :: installation(),
              metadata :: metadata()
            ) :: Plug.Conn.t()
  @callback handle_install_failure(conn :: Plug.Conn.t(), error :: install_error()) ::
              Plug.Conn.t()

  @optional_callbacks [handle_install_success: 3, handle_install_failure: 2]

  defmacro __using__(_opts) do
    quote do
      @behaviour Boltex.App

      import Boltex.App, only: [middleware: 1, handler: 1]

      Module.register_attribute(__MODULE__, :middleware_modules, accumulate: true)
      Module.register_attribute(__MODULE__, :handler_modules, accumulate: true)

      @before_compile Boltex.App
    end
  end

  defmacro middleware(module) do
    quote do
      @middleware_modules unquote(module)
    end
  end

  defmacro handler(module) do
    quote do
      @handler_modules unquote(module)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def middleware, do: Enum.reverse(@middleware_modules)
      def event_handlers, do: Enum.reverse(@handler_modules)
    end
  end

  @doc false
  def get(conn) do
    conn.assigns[:boltex_app] || conn.private[:boltex_app] ||
      raise "boltex_app not found in conn. Set it in router scope: scope \"/slack\", assigns: %{boltex_app: MyApp.Slack}"
  end
end
