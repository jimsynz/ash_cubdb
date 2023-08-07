defmodule AshCubDB.Info do
  @moduledoc """
  Auto-generated introspection for the AshCubDB DSL.
  """

  use Spark.InfoGenerator, sections: [:cubdb], extension: AshCubDB.DataLayer
  alias Spark.Dsl.Extension

  @doc """
  Retrieve the cached field layout for the resource.
  """
  @spec field_layout(Ash.Resource.t() | Spark.Dsl.t()) :: nil | {tuple, tuple}
  def field_layout(resource_or_dsl_state),
    do: Extension.get_persisted(resource_or_dsl_state, :cubdb_field_layout)
end
