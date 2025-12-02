defmodule Boltex.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/teampathio/boltex"

  def project do
    [
      app: :boltex,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "Boltex",
      source_url: @source_url,
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Boltex.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Core dependencies
      {:phoenix, "~> 1.7"},
      {:plug, "~> 1.14"},
      {:tesla, "~> 1.7"},
      {:jason, "~> 1.2"},

      # Database (for installations storage)
      {:ecto, "~> 3.10"},
      {:ecto_sql, "~> 3.10"},

      # Dev & Test
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:git_hooks, "~> 0.7", only: [:dev], runtime: false},
      {:mox, "~> 1.0", only: :test},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end

  defp description do
    """
    An unofficial Elixir library for building Slack apps, inspired by (but not affiliated with)
    Slack's official Bolt frameworks for Python and TypeScript.
    """
  end

  defp package do
    [
      name: "boltex",
      files: ~w(lib config .formatter.exs mix.exs README.md LICENSE),
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      main: "Boltex",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end
end
