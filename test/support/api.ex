defmodule Support.Api do
  @moduledoc false
  use Ash.Api

  resources do
    resource(Support.Author)
    resource(Support.Post)
  end
end
