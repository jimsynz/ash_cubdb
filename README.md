# AshCubDB

[![Build Status](https://drone.harton.dev/api/badges/james/ash_cubdb/status.svg?ref=refs/heads/main)](https://drone.harton.dev/james/ash_cubdb)
[![Hex.pm](https://img.shields.io/hexpm/v/ash_cubdb.svg)](https://hex.pm/packages/ash_cubdb)
[![Hippocratic License HL3-FULL](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-FULL&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/full.html)

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
    {:ash_cubdb, "~> 0.6.1"}
  ]
end
```

Documentation for the latest release can be found on
[HexDocs](https://hexdocs.pm/ash_cubdb) and for the `main` branch on
[docs.harton.nz](https://docs.harton.nz/james/ash_cubdb).

## License

This software is licensed under the terms of the
[HL3-FULL](https://firstdonoharm.dev), see the `LICENSE.md` file included with
this package for the terms.

This license actively proscribes this software being used by and for some
industries, countries and activities. If your usage of this software doesn't
comply with the terms of this license, then [contact me](mailto:james@harton.nz)
with the details of your use-case to organise the purchase of a license - the
cost of which may include a donation to a suitable charity or NGO.
