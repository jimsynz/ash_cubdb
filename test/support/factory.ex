defmodule Support.Factory do
  @moduledoc false
  alias Support.{Author, Post}

  def params!(resource, options \\ [])

  def params!(resource, options) do
    case Keyword.get(options, :count) do
      nil -> build_attrs(resource, options)
      count -> Enum.map(1..count, fn _ -> build_attrs(resource, options) end)
    end
  end

  def insert!(resource, options \\ []) do
    Ash.Seed.seed!(resource, params!(resource, options))
  end

  def insert(resource, options \\ []) do
    {:ok, insert!(resource, options)}
  rescue
    error -> {:error, error}
  end

  defp build_attrs(resource, options) do
    overrides = options |> Keyword.get(:attrs, %{}) |> Map.new()

    resource
    |> generate()
    |> Map.merge(overrides)
  end

  defp generate(Post),
    do: %{title: Support.Random.sentence(), body: Support.Random.paragraph()}

  defp generate(Author),
    do: %{name: Support.Random.name()}
end
