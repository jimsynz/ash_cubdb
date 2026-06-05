# AshCubDB

[![Hex.pm](https://img.shields.io/hexpm/v/ash_cubdb.svg)](https://hex.pm/packages/ash_cubdb)
[![Apache-2.0 License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0)

An [Ash DataLayer](https://ash-hq.org/docs/module/ash/latest/ash-datalayer)
which adds support for [CubDB](https://hex.pm/packages/cubdb).

## Status

AshCubDb is still a work in progress. Feel free to give it a go.

| Feature                 | Status |
| ----------------------- | ------ |
| Create                  | ✅     |
| Upsert (by primary key) | ✅     |
| Upsert (by identity)    | ❌     |
| Read (all)              | ✅     |
| Read (by primary key)   | ✅     |
| Read (filters)          | ✅     |
| Read (sort)             | ✅     |
| Read (distinct sort)    | ✅     |
| Read (calculations)     | ✅     |
| Read (aggregates)       | ❌     |
| Update                  | ✅     |
| Destroy                 | ✅     |
| Transactions            | ❌     |

## Github Mirror

This repository is mirrored [on Github](https://github.com/jimsynz/ash_cubdb)
from it's primary location [on my Forgejo instance](https://harton.dev/james/ash_cubdb).
Feel free to raise issues and open PRs on Github.

## Installation

AshCubDB is [available in Hex](https://hex.pm/packages/ash_cubdb), the package can be installed
by adding `ash_cubdb` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash_cubdb, "~> 0.6.3"}
  ]
end
```

Documentation for the latest release can be found on
[HexDocs](https://hexdocs.pm/ash_cubdb).

## License

This software is licensed under the terms of the
[Apache-2.0 License](https://www.apache.org/licenses/LICENSE-2.0), see the
`LICENSE.md` file included with this package for the terms.
