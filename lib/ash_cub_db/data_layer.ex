defmodule AshCubDB.DataLayer do
  alias AshCubDB.{
    CacheLayoutTransformer,
    ConfigureDirectoryTransformer,
    Dir,
    Dsl,
    Info,
    Query,
    Serde
  }

  alias Ash.{
    Actions.Sort,
    Changeset,
    Error,
    Error.Changes.InvalidAttribute,
    Error.Changes.StaleRecord,
    Error.Invalid.TenantRequired,
    Filter.Runtime,
    Resource
  }

  alias Ecto.Schema.Metadata
  alias Spark.Dsl.Extension

  import AshCubDB, only: [start: 1]

  @moduledoc """
  A CubDB data layer for Ash.

  <!--- ash-hq-hide-start --> <!--- -->

  ## DSL Documentation

  ### Index

  #{Extension.doc_index(Dsl.sections())}

  ### Docs

  #{Extension.doc(Dsl.sections())}
  <!--- ash-hq-hide-stop --> <!--- -->
  """

  @behaviour Ash.DataLayer

  use Extension,
    sections: Dsl.sections(),
    transformers: [ConfigureDirectoryTransformer, CacheLayoutTransformer]

  @doc false
  @impl true
  def can?(resource, :create), do: Dir.writable?(resource)
  def can?(resource, :update), do: Dir.writable?(resource)
  def can?(resource, :upsert), do: Dir.writable?(resource)
  def can?(resource, :read), do: Dir.readable?(resource)
  def can?(_, :multitenancy), do: true
  def can?(_, :filter), do: true
  def can?(_, {:filter_expr, _}), do: true
  def can?(_, :boolean_filter), do: true
  def can?(_, :sort), do: true
  def can?(_, {:sort, _}), do: true

  def can?(resource, capability) do
    if Application.get_env(:ash_cubdb, :debug_data_layer_capabilities?, false) do
      # credo:disable-for-next-line Credo.Check.Warning.Dbg
      dbg(resource: resource, capability: capability)
    end

    false
  end

  @doc false
  @impl true
  def create(resource, changeset) do
    with :ok <- validate_tenant_configuration(resource, changeset.tenant),
         {:ok, db} <- start(resource),
         {:ok, record} <- Changeset.apply_attributes(changeset),
         {:ok, key, data} <- Serde.serialise(record),
         {:ok, key} <- maybe_wrap_in_tenant(key, changeset),
         :ok <- CubDB.put_new(db, key, data) do
      {:ok, set_loaded(record)}
    else
      {:error, :exists} ->
        errors =
          resource
          |> Resource.Info.primary_key()
          |> Enum.map(
            &InvalidAttribute.exception(
              field: &1,
              message: "has already been taken"
            )
          )

        {:error, errors}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  @impl true
  def upsert(resource, changeset, keys) do
    pkey = Resource.Info.primary_key(resource)
    keys = keys || pkey

    {key_layout, _} = Info.field_layout(resource)

    cond do
      Enum.any?(keys, &is_nil(Changeset.get_attribute(changeset, &1))) ->
        create(resource, changeset)

      Tuple.to_list(key_layout) == Enum.sort(keys) ->
        do_direct_upsert(resource, changeset)

      true ->
        do_search_upsert(resource, changeset, keys)
    end
  end

  @doc false
  @impl true
  def update(resource, changeset) do
    with :ok <- validate_tenant_configuration(resource, changeset.tenant),
         {:ok, db} <- start(resource),
         {:ok, record} <- Changeset.apply_attributes(changeset),
         {:ok, key, data} <- Serde.serialise(record),
         true <- CubDB.has_key?(db, key),
         :ok <- CubDB.put(db, key, data) do
      {:ok, set_loaded(record)}
    else
      false -> {:error, StaleRecord.exception(resource: resource)}
      {:error, reason} -> {:error, Ash.Error.to_ash_error(reason)}
    end
  end

  @doc false
  @impl true
  def run_query(query, resource, parent \\ nil) do
    with :ok <- validate_tenant_configuration(resource, query.tenant),
         {:ok, db} <- start(resource),
         {:ok, stream} <- get_records(resource, db, query.tenant),
         {:ok, records} <- filter_matches(stream, query, parent),
         {:ok, records} <- runtime_sort(records, query) do
      {:ok, records}
    else
      {:error, reason} -> {:error, Error.to_ash_error(reason)}
    end
  end

  @doc false
  @impl true
  def resource_to_query(resource, api), do: %Query{resource: resource, api: api}

  @doc false
  @impl true
  def limit(query, limit, _), do: {:ok, %{query | limit: limit}}

  @doc false
  @impl true
  def offset(query, offset, _), do: {:ok, %{query | offset: offset}}

  @doc false
  @impl true
  def add_calculation(query, calculation, _, _),
    do: {:ok, %{query | calculations: [calculation | query.calculations]}}

  @doc false
  @impl true
  def add_aggregate(query, aggregate, _),
    do: {:ok, %{query | aggregates: [aggregate | query.aggregates]}}

  @doc false
  @impl true
  def set_tenant(_resource, query, tenant) do
    {:ok, %{query | tenant: tenant}}
  end

  @doc false
  @impl true
  def filter(query, filter, _resource) do
    if query.filter do
      {:ok, %{query | filter: Ash.Filter.add_to_filter!(query.filter, filter)}}
    else
      {:ok, %{query | filter: filter}}
    end
  end

  @doc false
  @impl true
  def sort(query, sort, _resource) do
    {:ok, %{query | sort: sort}}
  end

  @doc false
  @impl true
  def distinct(query, distinct, _resource) do
    {:ok, %{query | distinct: distinct}}
  end

  @impl true
  def distinct_sort(query, distinct_sort, _resource) do
    {:ok, %{query | distinct_sort: distinct_sort}}
  end

  defp set_loaded(record),
    do: %{record | __meta__: %Metadata{state: :loaded, schema: record.__struct__}}

  defp do_direct_upsert(resource, changeset) do
    with :ok <- validate_tenant_configuration(resource, changeset.tenant),
         {:ok, db} <- start(resource),
         {:ok, record} <- Changeset.apply_attributes(changeset),
         {:ok, key, data} <- Serde.serialise(record),
         {:ok, key} <- maybe_wrap_in_tenant(key, changeset),
         :ok <- CubDB.put(db, key, data) do
      {:ok, set_loaded(record)}
    end
  end

  defp do_search_upsert(_resource, _changeset, _keys) do
    {:error, :not_implemented}
  end

  defp get_records(resource, db, tenant) do
    stream =
      db
      |> CubDB.select()
      |> Stream.filter(&is_tuple(elem(&1, 0)))

    stream =
      if Resource.Info.multitenancy_strategy(resource) == :context do
        stream
        |> Stream.filter(fn {{t, _}, _} -> t == tenant end)
        |> Stream.map(fn {{_, key}, value} -> {key, value} end)
      else
        stream
      end

    stream =
      stream
      |> Stream.map(&Serde.deserialise!(resource, &1))

    {:ok, stream}
  end

  defp maybe_wrap_in_tenant(key, changeset) do
    if Resource.Info.multitenancy_strategy(changeset.resource) == :context do
      {:ok, {changeset.tenant, key}}
    else
      {:ok, key}
    end
  end

  defp validate_tenant_configuration(resource, tenant) do
    strategy = Resource.Info.multitenancy_strategy(resource)
    global? = Resource.Info.multitenancy_global?(resource)

    case {strategy, global?, tenant} do
      {strategy, false, nil} when not is_nil(strategy) ->
        {:error, TenantRequired.exception(resource: resource)}

      _ ->
        :ok
    end
  end

  defp filter_matches(stream, query, _parent) when is_nil(query.filter), do: {:ok, stream}

  defp filter_matches(stream, query, parent) do
    records =
      stream
      |> Enum.to_list()

    query.api
    |> Runtime.filter_matches(records, query.filter, parent: parent)
  end

  defp runtime_sort(records, query) when is_list(records) do
    records =
      records
      |> Sort.runtime_sort(query.distinct_sort || query.sort, api: query.api)
      |> Sort.runtime_distinct(query.distinct, api: query.api)
      |> Sort.runtime_sort(query.sort, api: query.api)
      |> Enum.drop(query.offset || 0)
      |> do_limit(query.limit)

    {:ok, records}
  end

  defp runtime_sort(records, query), do: records |> Enum.to_list() |> runtime_sort(query)

  defp do_limit(records, :infinity), do: records
  defp do_limit(records, limit), do: Enum.take(records, limit)
end
