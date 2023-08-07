defmodule AshCubDBTest do
  use ExUnit.Case
  doctest AshCubDB

  test "greets the world" do
    assert AshCubDB.hello() == :world
  end
end
