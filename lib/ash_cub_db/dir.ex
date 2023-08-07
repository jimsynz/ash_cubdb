defmodule AshCubDB.Dir do
  @moduledoc """
  Utilities for working with the underlying data directory.
  """

  alias AshCubDB.Info

  @doc """
  Is the directory able to be written to by the current user?
  """
  def writable?(resource) do
    with {:ok, dir} <- Info.cubdb_directory(resource),
         {:ok, stat} when stat.access in ~w[read_write write]a <- dir_stat(dir) do
      true
    else
      _ -> false
    end
  end

  @doc """
  Is the directory able to be read from by the current user?
  """
  def readable?(resource) do
    with {:ok, dir} <- Info.cubdb_directory(resource),
         {:ok, stat} when stat.access in ~w[read read_write]a <- dir_stat(dir) do
      true
    else
      _ -> false
    end
  end

  defp dir_stat(directory) do
    with {:error, :enoent} <- File.stat(directory),
         {:error, error} <- File.mkdir_p(directory) do
      {:error, "Unable to create directory: #{inspect(error)}"}
    else
      :ok -> File.stat(directory)
      {:ok, stat} -> {:ok, stat}
    end
  end
end
