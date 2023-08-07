defmodule AshCubDB.MixProject do
  use Mix.Project

  @version "0.1.0"

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
      source_url: "https://code.harton.nz/james/ash_cubdb",
      homepage_url: "https://code.harton.nz/james/ash_cubdb",
      aliases: aliases(),
      dialyzer: [plt_add_apps: [:faker, :smokestack]],
      docs: [
        main: "AshCubDB",
        extra_section: "Guides",
        formatters: ["html"],
        filter_modules: ~r/^Elixir.AshCubDB/,
        source_url_pattern:
          "https://code.harton.nz/james/ash_cub_db/src/branch/main/%{path}#L%{line}",
        spark: [
          extensions: [
            %{
              module: AshCubDB.DataLayer,
              name: "AshCubDB.DataLayer",
              target: "Ash.Resource",
              type: "Ash.DataLayer"
            }
          ]
        ]
      ]
    ]
  end

  def package do
    [
      maintainers: ["James Harton <james@harton.nz>"],
      licenses: ["HL3-FULL"],
      links: %{
        "Source" => "https://code.harton.nz/james/ash_cubdb"
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
      {:ash, "~> 2.13"},
      {:cubdb, "~> 2.0"},
      {:spark, "~> 1.1 and >= 1.1.39"},
      {:credo, "~> 1.7", opts},
      {:dialyxir, "~> 1.3", opts},
      {:doctor, "~> 0.21", opts},
      {:earmark, ">= 0.0.0", opts},
      {:ex_check, "~> 0.15", opts},
      {:ex_doc, ">= 0.0.0", opts},
      {:faker, "~> 0.17", opts},
      {:git_ops, "~> 2.6", opts},
      {:mix_audit, "~> 2.1", opts},
      {:smokestack, "~> 0.3", opts}
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
