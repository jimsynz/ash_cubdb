defmodule AshCubDB do
  @moduledoc """
  `AshCubDB` is an [Ash DataLayer](https://ash-hq.org/docs/module/ash/latest/ash-datalayer)
  which adds support for persisting Ash resources with [CubDB](https://hex.pm/packages/cubdb).

  CubDB is an Elixir-based key value store which supports all Erlang-native
  terms.  More information can be found in 
  [the CubDB readme](https://hexdocs.pm/cubdb/readme.html).
  """

  alias AshCubDB.{Info, Migration}

  @doc """
  Ensure that the CubDB process is running for the specified resource.
  """
  @spec start(Ash.Resource.t()) :: {:ok, pid} | {:error, any}
  def start(resource) do
    directory = Info.cubdb_directory!(resource)
    auto_compact? = Info.cubdb_auto_compact?(resource)
    auto_file_sync? = Info.cubdb_auto_file_sync?(resource)
    name = via(resource)

    with {:ok, pid} <-
           DynamicSupervisor.start_child(
             AshCubDB.DynamicSupervisor,
             {CubDB, [data_dir: directory, name: name]}
           ),
         :ok <- CubDB.set_auto_compact(pid, auto_compact?),
         :ok <- CubDB.set_auto_file_sync(pid, auto_file_sync?),
         :ok <- Migration.check(pid, resource) do
      {:ok, pid}
    else
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Stop the CubDB process running for a specific resource.
  """
  @spec stop(Ash.Resource.t()) :: :ok
  def stop(resource) do
    AshCubDB
    |> Registry.lookup(resource)
    |> Enum.each(&DynamicSupervisor.terminate_child(AshCubDB.DynamicSupervisor, &1))
  end

  @doc """
  Creates a backup of the database into the target directory path.

  Wrapper around `CubDB.back_up/2`
  """
  @spec back_up(Ash.Resource.t(), Path.t()) :: :ok | {:error, any}
  def back_up(resource, target_path) do
    case start(resource) do
      {:ok, pid} -> CubDB.back_up(pid, target_path)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Deletes all entries, resulting in an empty database.

  Wrapper around `CubDB.clear/1`
  """
  @spec clear(Ash.Resource.t()) :: :ok
  def clear(resource) do
    case start(resource) do
      {:ok, pid} -> CubDB.clear(pid)
      _ -> :ok
    end
  end

  @doc """
  Runs a database compaction.

  Wrapper around `CubDB.compact/1`
  """
  @spec compact(Ash.Resource.t()) :: :ok | {:error, any}
  def compact(resource) do
    case start(resource) do
      {:ok, pid} -> CubDB.compact(pid)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Returns true if a compaction operation is currently running, false otherwise.

  Wrapper around `CubDB.compacting?/1`
  """
  @spec compacting?(Ash.Resource.t()) :: boolean
  def compacting?(resource) do
    case start(resource) do
      {:ok, pid} -> CubDB.compacting?(pid)
      _ -> false
    end
  end

  @doc """
  Returns the path of the current database file.

  Wrapper around `CubDB.current_db_file/1`
  """
  @spec current_db_file(Ash.Resource.t()) :: String.t()
  def current_db_file(resource) do
    resource
    |> via()
    |> CubDB.current_db_file()
  end

  @doc """
  Returns the path of the data directory, as given when the `CubDB` process was started. 

  Wrapper around `CubDB.data_dir/1`
  """
  @spec data_dir(Ash.Resource.t()) :: String.t()
  def data_dir(resource) do
    resource
    |> via()
    |> CubDB.data_dir()
  end

  @doc """
  Returns the dirt factor.

  Wrapper around `CubDB.dirt_factor/1`
  """
  @spec dirt_factor(Ash.Resource.t()) :: float
  def dirt_factor(resource) do
    resource
    |> via()
    |> CubDB.dirt_factor()
  end

  @doc """
  Performs an `fsync`, forcing to flush all data that might be buffered by the OS to disk.

  Wrapper around `CubDB.file_sync/1`
  """
  @spec file_sync(Ash.Resource.t()) :: :ok
  def file_sync(resource) do
    resource
    |> via()
    |> CubDB.file_sync()
  end

  @doc """
  Stops a running compaction.

  Wrapper around `CubDB.halt_compaction/1`
  """
  @spec halt_compaction(Ash.Resource.t()) :: :ok | {:error, :no_compaction_running}
  def halt_compaction(resource) do
    resource
    |> via()
    |> CubDB.halt_compaction()
  end

  defp via(resource), do: {:via, Registry, {AshCubDB.Registry, resource}}
end
