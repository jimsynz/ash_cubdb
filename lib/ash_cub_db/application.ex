defmodule AshCubDB.Application do
  @moduledoc false

  use Application

  @doc false
  @impl true
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, strategy: :one_for_one, name: AshCubDB.DynamicSupervisor},
      {Registry, keys: :unique, name: AshCubDB.Registry}
    ]

    opts = [strategy: :one_for_one, name: AshCubDB.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
