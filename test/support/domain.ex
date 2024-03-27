defmodule Support.Domain do
  @moduledoc false
  use Ash.Domain

  resources do
    resource Support.Author
    resource Support.Post
  end
end
