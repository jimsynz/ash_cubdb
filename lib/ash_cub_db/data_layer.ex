defmodule AshCubDB.DataLayer do
  alias AshCubDB.{
    CacheLayoutTransformer,
    ConfigureDirectoryTransformer,
    Dir,
    Dsl,
    Info,
    Lock,
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
  def can?(resource, :destroy), do: Dir.writable?(resource)
  def can?(resource, :read), do: Dir.readable?(resource)
  def can?(_, :multitenancy), do: true
  def can?(_, :filter), do: true
  def can?(_, :limit), do: true
  def can?(_, :offset), do: true
  def can?(_, :distinct), do: true
  def can?(_, :distinct_sort), do: true
  def can?(_, {:filter_expr, _}), do: true
  def can?(_, :boolean_filter), do: true
  def can?(_, :sort), do: true
  def can?(_, {:sort, _}), do: true
  def can?(_, :nested_expressions), do: true
  def can?(_, :transact), do: true

  def can?(_resource, _capability), do: false

  @undo :ash_cubdb_transaction_undo

  # A transaction holds the lock of each resource it touches, so a read and the write that
  # depends on it cannot interleave with another transaction's, and it records each key it
  # changes, so a rollback can put it back. The resources an action touches are locked up
  # front, in one order, and waited for; a resource first locked inside a transaction is
  # tried once, so transactions never wait in a cycle. One that outlives its timeout is
  # undone when it finishes, as a database refuses to commit.
  @doc false
  @impl true
  def transaction(resource, func, timeout, reason) do
    deadline = deadline(timeout)

    {locks, mode} =
      if holding_locks?() do
        {[lock(resource, reason)], :try}
      else
        {transaction_locks(resource, reason), :wait}
      end

    locks
    |> with_locks(mode, deadline, fn ->
      Process.put(@undo, [%{} | Process.get(@undo, [])])

      try do
        result = func.()

        if past?(deadline) do
          undo()
          :timeout
        else
          commit_undo()
          {:res, result}
        end
      catch
        {{:ash_cubdb_rollback, ^resource}, value} ->
          undo()
          {:error, value}

        kind, error ->
          undo()
          :erlang.raise(kind, error, __STACKTRACE__)
      end
    end)
    |> case do
      {:res, result} ->
        {:ok, result}

      {:error, error} ->
        {:error, error}

      :timeout ->
        {:error, Error.Invalid.Timeout.exception(timeout: timeout, name: name(reason, resource))}

      :busy ->
        {:error, "could not lock #{inspect(resource)}, first written inside another transaction"}
    end
  end

  @doc false
  @impl true
  def rollback(resource, value), do: throw({{:ash_cubdb_rollback, resource}, value})

  @doc false
  @impl true
  def in_transaction?(resource), do: Process.get({:ash_cubdb_transaction, resource}, false)

  defp with_locks([], _mode, _deadline, fun), do: fun.()

  defp with_locks([{resource, tenant} | locks], mode, deadline, fun) do
    ref = make_ref()

    case Lock.lock(resource, tenant, ref, mode, remaining(deadline)) do
      :ok ->
        Process.put({:ash_cubdb_transaction, resource}, true)

        try do
          with_locks(locks, mode, deadline, fun)
        after
          Process.delete({:ash_cubdb_transaction, resource})
          Lock.unlock(resource, tenant, ref)
        end

      refused ->
        refused
    end
  end

  defp deadline(timeout) when is_integer(timeout),
    do: System.monotonic_time(:millisecond) + timeout

  defp deadline(_), do: :infinity

  defp remaining(:infinity), do: :infinity
  defp remaining(deadline), do: max(deadline - System.monotonic_time(:millisecond), 0)

  defp past?(:infinity), do: false
  defp past?(deadline), do: System.monotonic_time(:millisecond) > deadline

  defp name(%{metadata: %{resource: resource, action: action}}, _) when is_atom(action),
    do: "#{inspect(resource)}.#{action}"

  defp name(_, resource), do: inspect(resource)

  defp holding_locks? do
    Enum.any?(Process.get_keys(true), &match?({:ash_cubdb_transaction, _}, &1))
  end

  defp transaction_locks(resource, reason) do
    [resource | touched_resources(reason)]
    |> Enum.filter(&(Ash.DataLayer.data_layer(&1) == __MODULE__))
    |> Enum.map(&lock(&1, reason))
    |> Enum.uniq()
    |> Enum.sort()
  end

  # One store holds every tenant of a resource, under keys wrapped in the tenant, so
  # tenants of a context-multitenant resource do not contend for one lock.
  defp lock(resource, reason) do
    tenant =
      if Resource.Info.multitenancy_strategy(resource) == :context do
        Map.get(reason, :tenant)
      end

    {resource, tenant}
  end

  defp touched_resources(%{metadata: %{resource: resource, action: action}})
       when is_atom(action) do
    case Resource.Info.action(resource, action) do
      %{touches_resources: touches_resources} -> [resource | touches_resources]
      _ -> [resource]
    end
  end

  defp touched_resources(%{
         metadata: %{query: %{action: %{touches_resources: touches_resources}}}
       }),
       do: touches_resources

  defp touched_resources(_), do: []

  # The value each key held before the transaction first changed it, `:error` for none, so
  # a rollback restores the store to what it was. Outside a transaction, nothing to keep.
  defp remember(db, keys) do
    case Process.get(@undo) do
      [changes | parents] ->
        Process.put(@undo, [Enum.reduce(keys, changes, &record_prior(db, &1, &2)) | parents])
        :ok

      _ ->
        :ok
    end
  end

  defp record_prior(db, key, changes),
    do: Map.put_new_lazy(changes, {db, key}, fn -> CubDB.fetch(db, key) end)

  # A committed transaction inside another hands its changes to it, keeping what the outer
  # one recorded first.
  defp commit_undo do
    case Process.get(@undo) do
      [_changes] -> Process.delete(@undo)
      [changes, outer | rest] -> Process.put(@undo, [Map.merge(changes, outer) | rest])
    end
  end

  defp undo do
    [changes | rest] = Process.get(@undo)

    if rest == [], do: Process.delete(@undo), else: Process.put(@undo, rest)

    Enum.each(changes, fn
      {{db, key}, :error} -> CubDB.delete(db, key)
      {{db, key}, {:ok, value}} -> CubDB.put(db, key, value)
    end)
  end

  @doc false
  @impl true
  def create(resource, changeset) do
    with :ok <- validate_tenant_configuration(resource, changeset.tenant),
         {:ok, db} <- start(resource),
         {:ok, record} <- Changeset.apply_attributes(changeset),
         {:ok, key, data} <- Serde.serialise(record),
         {:ok, key} <- maybe_wrap_in_tenant(key, changeset),
         :ok <- remember(db, [key]),
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
         {:ok, key} <- maybe_wrap_in_tenant(key, changeset),
         true <- CubDB.has_key?(db, key),
         :ok <- remember(db, [key]),
         :ok <- CubDB.put(db, key, data) do
      {:ok, set_loaded(record)}
    else
      false -> {:error, StaleRecord.exception(resource: resource)}
      {:error, reason} -> {:error, Ash.Error.to_ash_error(reason)}
    end
  end

  @doc false
  @impl true
  def destroy(resource, changeset) do
    with :ok <- validate_tenant_configuration(resource, changeset.tenant),
         {:ok, db} <- start(resource),
         {:ok, key, _data} <- Serde.serialise(changeset.data),
         {:ok, key} <- maybe_wrap_in_tenant(key, changeset),
         true <- CubDB.has_key?(db, key),
         :ok <- remember(db, [key]) do
      CubDB.delete(db, key)
    else
      false -> {:error, StaleRecord.exception(resource: resource)}
      {:error, reason} -> {:error, reason}
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
  def resource_to_query(resource, domain), do: %Query{resource: resource, domain: domain}

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
         :ok <- remember(db, [key]),
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

    query.domain
    |> Runtime.filter_matches(records, query.filter, parent: parent)
  end

  defp runtime_sort(records, query) when is_list(records) do
    records =
      records
      |> Sort.runtime_sort(query.distinct_sort || query.sort, domain: query.domain)
      |> Sort.runtime_distinct(query.distinct, domain: query.domain)
      |> Sort.runtime_sort(query.sort, domain: query.domain)
      |> Enum.drop(query.offset || 0)
      |> do_limit(query.limit)

    {:ok, records}
  end

  defp runtime_sort(records, query), do: records |> Enum.to_list() |> runtime_sort(query)

  defp do_limit(records, :infinity), do: records
  defp do_limit(records, limit), do: Enum.take(records, limit)
end
