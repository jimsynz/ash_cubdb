defmodule Support.Post do
  @moduledoc false
  use Ash.Resource, data_layer: AshCubDB.DataLayer, domain: Support.Domain

  cubdb do
    otp_app :ash_cubdb
  end

  attributes do
    uuid_primary_key :id, writable?: true, public?: true
    attribute :title, :string, public?: true
    attribute :body, :string, public?: true
  end

  actions do
    default_accept [:id, :title, :body]
    defaults ~w[create read update destroy]a
  end

  calculations do
    calculate :all_text, :string, expr(title <> body)
  end

  relationships do
    belongs_to :author, Support.Author
  end

  code_interface do
    define :create
    define :read
    define :update
    define :get, action: :read, get_by: [:id]
    define :destroy
  end
end
