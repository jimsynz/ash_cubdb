defmodule AshCubDB.TransactionTest do
  @moduledoc false
  use ExUnit.Case, async: false
  alias Support.{Account, Left, Right}

  setup do
    on_exit(fn ->
      AshCubDB.clear(Account)
      AshCubDB.clear(Left)
      AshCubDB.clear(Right)
    end)
  end

  test "it can transact" do
    assert AshCubDB.DataLayer.can?(Account, :transact)
  end

  test "simultaneous creates of one identity value keep one record" do
    results = at_once(20, fn _ -> Ash.create(Account, %{email: "same@example.com"}) end)

    assert Enum.count(results, &match?({:ok, _}, &1)) == 1
    assert Enum.count(results, &match?({:error, %Ash.Error.Invalid{}}, &1)) == 19
    assert [_] = Ash.read!(Account)
  end

  test "a rollback undoes the writes made in the transaction" do
    assert {:error, _} =
             Ash.transaction(Account, fn ->
               Ash.create!(Account, %{email: "kept@example.com"})
               Ash.DataLayer.rollback(Account, :rolled_back)
             end)

    assert [] = Ash.read!(Account)
  end

  test "an action that raises after its write leaves no record" do
    result =
      try do
        Ash.create(Account, %{email: "gone@example.com"}, action: :create_then_fail)
      rescue
        error -> {:raised, error}
      end

    refute match?({:ok, _}, result)
    assert [] = Ash.read!(Account)
  end

  test "actions that lock each other's resources in opposite orders all complete" do
    results =
      for _round <- 1..10 do
        at_once(2, fn
          1 -> Ash.create(Left, %{})
          2 -> Ash.create(Right, %{})
        end)
      end

    assert Enum.all?(List.flatten(results), &match?({:ok, _}, &1))
  end

  # Runs `fun` for 1..count in as many processes released together, giving each three
  # seconds; one still running then is reported as `:still_running`.
  defp at_once(count, fun) do
    tasks =
      for n <- 1..count do
        Task.async(fn ->
          receive do
            :go -> fun.(n)
          end
        end)
      end

    Enum.each(tasks, &send(&1.pid, :go))

    tasks
    |> Task.yield_many(3_000)
    |> Enum.map(fn
      {_task, {:ok, result}} ->
        result

      {task, nil} ->
        Task.shutdown(task, :brutal_kill)
        :still_running
    end)
  end
end
