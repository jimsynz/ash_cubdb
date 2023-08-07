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
      deps: deps(),
      description: @moduledoc,
      package: package(),
      source_url: "https://code.harton.nz/james/ash_cubdb",
      homepage_url: "https://code.harton.nz/james/ash_cubdb",
      aliases: aliases()
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
      {:cubdb, "~> 2.0"},
      {:credo, "~> 1.7", opts},
      {:dialyxir, "~> 1.3", opts},
      {:doctor, "~> 0.21", opts},
      {:earmark, ">= 0.0.0", opts},
      {:ex_check, "~> 0.15", opts},
      {:ex_doc, ">= 0.0.0", opts},
      {:git_ops, "~> 2.6", opts},
      {:mix_audit, "~> 2.1", opts}
    ]
  end

  defp aliases do
    [
      "spark.formatter": "spark.formatter --extensions=AshCubDB.DataLayer"
    ]
  end
end
