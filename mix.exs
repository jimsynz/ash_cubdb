defmodule AshCubDB.MixProject do
  use Mix.Project

  @version "0.6.1"

  @moduledoc """
  A CubDB data layer for `Ash` resources.
  """

  def project do
    [
      app: :ash_cubdb,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() != :test,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      description: @moduledoc,
      package: package(),
      source_url: "https://harton.dev/james/ash_cubdb",
      homepage_url: "https://harton.dev/james/ash_cubdb",
      aliases: aliases(),
      dialyzer: [plt_add_apps: [:faker, :smokestack]],
      docs: [
        main: "readme",
        extra_section: "Guides",
        formatters: ["html"],
        filter_modules: ~r/^Elixir.AshCubDB/,
        source_url_pattern:
          "https://harton.dev/james/ash_cub_db/src/branch/main/%{path}#L%{line}",
        extras: [
          "README.md",
          "CHANGELOG.md",
          "documentation/dsls/DSL:-AshCubDB.DataLayer.md"
        ],
        groups_for_extras: [
          Tutorials: ~r'documentation/tutorials',
          "How To": ~r'documentation/how_to',
          Topics: ~r'documentation/topics',
          DSLs: ~r'documentation/dsls'
        ]
      ]
    ]
  end

  def package do
    [
      maintainers: ["James Harton <james@harton.nz>"],
      licenses: ["HL3-FULL"],
      links: %{
        "Source" => "https://harton.dev/james/ash_cubdb",
        "GitHub" => "https://github.com/jimsynz/ash_cubdb",
        "Changelog" => "https://docs.harton.nz/james/ash_cubdb/changelog.html",
        "Sponsor" => "https://github.com/sponsors/jimsynz"
      }
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AshCubDB.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    opts = [only: ~w[dev test]a, runtime: false]

    [
      {:ash, "== 3.0.0-rc.5"},
      {:cubdb, "~> 2.0"},
      {:spark, "~> 2.1"},
      {:earmark, ">= 0.0.0"},
      {:credo, "~> 1.7", opts},
      {:dialyxir, "~> 1.3", opts},
      {:doctor, "~> 0.21", opts},
      {:ex_check, "~> 0.16", opts},
      {:ex_doc, ">= 0.0.0", opts},
      {:faker, "~> 0.18", opts},
      {:git_ops, "~> 2.6", opts},
      {:mix_audit, "~> 2.1", opts},
      {:smokestack, "== 0.6.1-rc.0", opts}
    ]
  end

  defp aliases do
    [
      "spark.formatter": "spark.formatter --extensions=AshCubDB.DataLayer",
      "spark.cheat_sheets": "spark.cheat_sheets --extensions=AshCubDB.DataLayer"
    ]
  end

  defp elixirc_paths(env) when env in ~w[dev test]a, do: ~w[lib test/support]
  defp elixirc_paths(_), do: ~w[lib]
end
