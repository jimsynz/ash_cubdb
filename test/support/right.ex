defmodule Support.Right do
  @moduledoc false
  use Ash.Resource, data_layer: AshCubDB.DataLayer, domain: Support.Domain

  cubdb do
    otp_app :ash_cubdb
  end

  attributes do
    uuid_primary_key :id
  end

  actions do
    defaults ~w[read]a

    create :create do
      primary? true
      touches_resources [Support.Left]
    end
  end
end
