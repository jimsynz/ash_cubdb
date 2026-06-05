defmodule Support.Random do
  @moduledoc false

  @words ~w[
    lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod
    tempor incididunt ut labore et dolore magna aliqua enim ad minim veniam
    quis nostrud exercitation ullamco laboris nisi aliquip ex ea commodo
  ]

  @given_names ~w[Ada Alan Barbara Edsger Grace Haskell Ken Linus Margaret Rob]
  @family_names ~w[Lovelace Turing Liskov Dijkstra Hopper Curry Thompson Torvalds Hamilton Pike]

  def words(count), do: Enum.map(1..count, fn _ -> Enum.random(@words) end)

  def sentence do
    words(Enum.random(4..8))
    |> Enum.join(" ")
    |> String.capitalize()
    |> Kernel.<>(".")
  end

  def paragraph do
    Enum.map_join(1..Enum.random(3..5), " ", fn _ -> sentence() end)
  end

  def name, do: "#{Enum.random(@given_names)} #{Enum.random(@family_names)}"
end
