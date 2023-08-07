defmodule AshCubDB.CacheLayoutTransformer do
  @moduledoc false

  alias Ash.Resource.Info
  alias Spark.{Dsl, Dsl.Transformer, Error.DslError}
  use Transformer

  @doc false
  @impl true
  @spec after?(module) :: boolean
  def after?(_), do: true

  @doc false
  @impl true
  @spec transform(Dsl.t()) :: {:ok, Dsl.t()} | {:error, DslError.t()}
  def transform(dsl_state) do
    key =
      dsl_state
      |> Info.attributes()
      |> Enum.filter(& &1.primary_key?)
      |> Enum.map(& &1.name)
      |> Enum.sort()
      |> Enum.uniq()
      |> List.to_tuple()

    attributes =
      dsl_state
      |> Info.attributes()
      |> Enum.reject(& &1.primary_key?)
      |> Enum.map(& &1.name)
      |> Enum.sort()
      |> Enum.uniq()
      |> List.to_tuple()

    layout = {key, attributes}

    {:ok, Transformer.persist(dsl_state, :cubdb_field_layout, layout)}
  end
end
