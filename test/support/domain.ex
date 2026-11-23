defmodule Support.Domain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Support.Account
    resource Support.Author
    resource Support.Left
    resource Support.Post
    resource Support.Right
  end
end
