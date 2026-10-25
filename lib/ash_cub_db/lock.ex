defmodule AshCubDB.Lock do
  @moduledoc false

  # A resource's transaction lock: one transaction at a time, the rest waiting in the order
  # they asked, as a pool checks out a connection. A holder that exits gives it up.
  use GenServer

  @doc false
  def start_link(name), do: GenServer.start_link(__MODULE__, nil, name: name)

  @doc false
  def lock(resource, tenant, ref, mode, timeout) do
    name = name(resource, tenant)

    case DynamicSupervisor.start_child(AshCubDB.DynamicSupervisor, {__MODULE__, name}) do
      {:ok, _pid} -> call_lock(name, ref, mode, timeout)
      {:error, {:already_started, _pid}} -> call_lock(name, ref, mode, timeout)
      {:error, reason} -> {:error, reason}
    end
  end

  @doc false
  def unlock(resource, tenant, ref) do
    GenServer.call(name(resource, tenant), {:unlock, ref})
  catch
    # The lock stopped, and released its holder with it.
    :exit, _ -> :ok
  end

  defp call_lock(name, ref, mode, timeout) do
    GenServer.call(name, {:lock, ref, mode}, timeout)
  catch
    :exit, {:timeout, _} ->
      GenServer.cast(name, {:cancel, ref})
      :timeout

    # The lock stopped while the transaction waited for it.
    :exit, reason ->
      {:error, Exception.format_exit(reason)}
  end

  defp name(resource, tenant),
    do: {:via, Registry, {AshCubDB.Registry, {__MODULE__, resource, tenant}}}

  @impl true
  def init(nil), do: {:ok, %{holder: nil, waiting: :queue.new()}}

  # A `:try` request is refused rather than queued, so a transaction that already holds a
  # lock never waits for another one.
  @impl true
  def handle_call({:lock, ref, mode}, {pid, _} = from, state) do
    cond do
      is_nil(state.holder) -> {:reply, :ok, hold(state, pid, ref)}
      mode == :try -> {:reply, :busy, state}
      true -> {:noreply, %{state | waiting: :queue.in({from, ref}, state.waiting)}}
    end
  end

  def handle_call({:unlock, ref}, _from, state), do: {:reply, :ok, release(state, ref)}

  # A waiter that gave up: forgotten if still waiting, released if granted meanwhile.
  @impl true
  def handle_cast({:cancel, ref}, state) do
    waiting = :queue.filter(fn {_from, waiting} -> waiting != ref end, state.waiting)
    {:noreply, release(%{state | waiting: waiting}, ref)}
  end

  @impl true
  def handle_info({:DOWN, monitor, :process, _, _}, %{holder: {_, monitor, ref}} = state),
    do: {:noreply, release(state, ref)}

  def handle_info(_, state), do: {:noreply, state}

  defp hold(state, pid, ref), do: %{state | holder: {pid, Process.monitor(pid), ref}}

  defp release(%{holder: {_pid, monitor, ref}} = state, ref) do
    Process.demonitor(monitor, [:flush])
    grant_next(%{state | holder: nil})
  end

  defp release(state, _ref), do: state

  defp grant_next(state) do
    case :queue.out(state.waiting) do
      {:empty, _} ->
        state

      {{:value, {{pid, _} = from, ref}}, waiting} ->
        if Process.alive?(pid) do
          GenServer.reply(from, :ok)
          hold(%{state | waiting: waiting}, pid, ref)
        else
          grant_next(%{state | waiting: waiting})
        end
    end
  end
end
