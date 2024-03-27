defmodule Support.Author do
  @moduledoc false
  use Ash.Resource, data_layer: AshCubDB.DataLayer, domain: Support.Domain

  cubdb do
    otp_app :ash_cubdb
  end

  multitenancy do
    strategy :context
    global? true
  end

  attributes do
    uuid_primary_key :id

    attribute :name, :ci_string, public?: true
  end

  relationships do
    has_many :posts, Support.Post
  end

  actions do
    default_accept :*
    defaults ~w[create read]a
  end

  code_interface do
    define :create
    define :read
  end
end
