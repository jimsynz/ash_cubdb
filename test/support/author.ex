defmodule Support.Author do
  @moduledoc false
  use Ash.Resource, data_layer: AshCubDB.DataLayer

  cubdb do
    otp_app :ash_cubdb
  end

  multitenancy do
    strategy(:context)
    global?(true)
  end

  attributes do
    uuid_primary_key(:id)

    attribute(:name, :ci_string)
  end

  relationships do
    has_many(:posts, Support.Post)
  end

  actions do
    defaults(~w[create read]a)
  end

  code_interface do
    define_for(Support.Api)

    define(:create)
    define(:read)
  end
end
