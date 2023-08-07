defmodule AshCubDB.Serde do
  @moduledoc """
  Handle serialising and deserialising of records into CubDB.
  """

  alias Ash.{Resource, Type}
  alias AshCubDB.Info
  alias Ecto.Schema.Metadata

  @doc """
  Serialise the record into key and value tuples for storage in CubDB.
  """
  @spec serialise(Resource.record()) :: {:ok, tuple, tuple} | {:error, any}
  def serialise(record) do
    {key_layout, data_layout} =
      record.__struct__
      |> Info.field_layout()

    with {:ok, key} <- serialise_with_layout(record, key_layout),
         {:ok, data} <- serialise_with_layout(record, data_layout) do
      {:ok, key, data}
    end
  end

  @doc false
  @spec deserialise!(Resource.t(), {tuple, tuple}) :: Resource.record() | no_return
  def deserialise!(resource, {key, data}) do
    case deserialise(resource, key, data) do
      {:ok, record} -> record
      {:error, reason} -> raise reason
    end
  end

  @doc """
  Convert the key and data back into a record..
  """
  @spec deserialise(Resource.t(), tuple, tuple) :: {:ok, Resource.record()} | {:error, any}
  def deserialise(resource, key, data) do
    {key_layout, data_layout} = Info.field_layout(resource)

    with {:ok, key_map} <- deserialise_with_layout(resource, key, key_layout),
         {:ok, data_map} <- deserialise_with_layout(resource, data, data_layout) do
      attrs = Map.merge(key_map, data_map)
      record = struct(resource, attrs)

      {:ok, %{record | __meta__: %Metadata{state: :loaded, schema: resource}}}
    end
  end

  defp serialise_with_layout(record, layout) do
    layout
    |> Tuple.to_list()
    |> Enum.reduce_while({:ok, {}}, fn attr, {:ok, result} ->
      with {:ok, value} <- fetch_record_attribute(record, attr),
           {:ok, attr} <- fetch_attribute_definition(record.__struct__, attr),
           {:ok, casted} <- Type.dump_to_native(attr.type, value, attr.constraints) do
        {:cont, {:ok, Tuple.append(result, casted)}}
      else
        :error -> {:halt, {:error, "Failed to dump value as type `#{attr.type}`"}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp deserialise_with_layout(resource, data, layout) do
    layout
    |> Tuple.to_list()
    |> Enum.zip(Tuple.to_list(data))
    |> Enum.reduce_while({:ok, %{}}, fn {attr, value}, {:ok, result} ->
      with {:ok, attr} <- fetch_attribute_definition(resource, attr),
           {:ok, value} <- Type.cast_stored(attr.type, value, attr.constraints) do
        {:cont, {:ok, Map.put(result, attr.name, value)}}
      else
        :error -> {:halt, {:error, "Failed to load `#{inspect(value)}`."}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp fetch_record_attribute(record, attribute_name) do
    case Map.fetch(record, attribute_name) do
      {:ok, value} ->
        {:ok, value}

      :error ->
        {:error,
         "Unable to retreive attribute `#{attribute_name}` from resource `#{inspect(record.__struct__)}`"}
    end
  end

  defp fetch_attribute_definition(resource, attribute_name) do
    case Resource.Info.attribute(resource, attribute_name) do
      nil ->
        {:error, "Attribute `#{attribute_name}` not found on resource `#{inspect(resource)}`"}

      attribute ->
        {:ok, attribute}
    end
  end
end
