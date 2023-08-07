defmodule AshCubDB.Migration do
  @moduledoc """
  We store and check metadata when opening a database to ensure that the
  resource and attributes match, and possibly perform migrations.
  """

  alias AshCubDB.Info

  @doc """
  Check that a newly opened database doesn't need to be migrated.
  """
  @spec check(GenServer.server(), Ash.Resource.t()) :: :ok | {:error, any}
  def check(db, resource) do
    layout = Info.field_layout(resource)

    case CubDB.fetch(db, :__metadata_) do
      :error ->
        CubDB.put(db, :__metadata__, %{resource: resource, layout: layout})

      {:ok, metadata} when metadata.resource == resource and metadata.layout == layout ->
        :ok

      {:ok, metadata} when metadata.resource != resource ->
        {:error,
         "CubDB database refers to resource `#{metadata.resource}`, but should be `#{inspect(resource)}`."}

      {:ok, _} ->
        {:error, "CubDB database needs to be migrated."}
    end
  end
end
