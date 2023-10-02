defmodule Support.Post do
  @moduledoc false
  use Ash.Resource, data_layer: AshCubDB.DataLayer

  cubdb do
    otp_app :ash_cubdb
  end

  attributes do
    uuid_primary_key :id do
      writable? true
    end

    attribute :title, :string
    attribute :body, :string
  end

  actions do
    # defaults ~w[create read update destroy]a
    defaults ~w[create read update]a
  end

  relationships do
    belongs_to :author, Support.Author
  end

  code_interface do
    define_for Support.Api

    define :create
    define :read
    define :update
    define :get, action: :read, get_by: [:id]
  end
end
