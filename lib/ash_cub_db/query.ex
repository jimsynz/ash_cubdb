defmodule AshCubDB.Query do
  @moduledoc """
  A struct which holds information about a resource query as it is being built.
  """

  alias Ash.{Domain, Filter, Resource}

  defstruct aggregates: [],
            domain: nil,
            calculations: [],
            distinct: nil,
            distinct_sort: nil,
            filter: nil,
            limit: :infinity,
            offset: 0,
            relationships: %{},
            resource: nil,
            sort: nil,
            tenant: nil

  @type t :: %__MODULE__{
          aggregates: [Resource.Aggregate.t()],
          domain: Domain.t(),
          calculations: [Resource.Calculation.t()],
          distinct: Ash.Sort.t(),
          distinct_sort: Ash.Sort.t(),
          filter: nil | Filter.t(),
          limit: :infinity | non_neg_integer(),
          offset: non_neg_integer(),
          relationships: %{optional(atom) => Ash.Resource.Relationships.relationship()},
          resource: Ash.Resource.t(),
          sort: nil | Ash.Sort.t(),
          tenant: any
        }
end
