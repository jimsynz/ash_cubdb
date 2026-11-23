defmodule Support.Account do
  @moduledoc false
  use Ash.Resource, data_layer: AshCubDB.DataLayer, domain: Support.Domain

  cubdb do
    otp_app :ash_cubdb
  end

  attributes do
    uuid_primary_key :id
    attribute :email, :string, public?: true
  end

  identities do
    identity :unique_email, [:email], pre_check_with: Support.Domain
  end

  actions do
    default_accept [:email]
    defaults ~w[create read destroy]a

    create :create_then_fail do
      change after_action(fn _changeset, _record, _context ->
               raise "after the write"
             end)
    end
  end
end
