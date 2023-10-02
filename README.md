# AshCubDB

[![Build Status](https://drone.harton.nz/api/badges/james/ash_cubdb/status.svg?ref=refs/heads/main)](https://drone.harton.nz/cinder/cinder)
[![Hippocratic License HL3-FULL](https://img.shields.io/static/v1?label=Hippocratic%20License&message=HL3-FULL&labelColor=5e2751&color=bc8c3d)](https://firstdonoharm.dev/version/3/0/full.html)

An [Ash DataLayer](https://ash-hq.org/docs/module/ash/latest/ash-datalayer)
which adds support for [CubDB](https://hex.pm/packages/cubdb).

## Status

AshCubDb is still a work in progress.  Feel free to give it a go.

| Feature                 | Status |
|-------------------------|--------|
| Create                  | ✅     |
| Upsert (by primary key) | ✅     |
| Upsert (by identity)    | ❌     |
| Read (all)              | ✅     |
| Read (by primary key)   | ✅     |
| Read (filters)          | ✅     |
| Read (sort)             | ✅     |
| Read (calculations)     | ❌     |
| Read (aggregates)       | ❌     |
| Update                  | ✅     |
| Destroy                 | ❌     |

## Github Mirror

This repository is mirrored [on Github](https://github.com/jimsynz/smokestack)
from it's primary location [on my Forejo instance](https://code.harton.nz/james/ash_cubdb).
Feel free to raise issues and open PRs on Github.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ash_cubdb` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ash_cubdb, "~> 0.3.0"}
  ]
end
```

## License

This software is licensed under the terms of the
[HL3-FULL](https://firstdonoharm.dev), see the `LICENSE.md` file included with
this package for the terms.

This license actively proscribes this software being used by and for some
industries, countries and activities. If your usage of this software doesn't
comply with the terms of this license, then [contact me](mailto:james@harton.nz)
with the details of your use-case to organise the purchase of a license - the
cost of which may include a donation to a suitable charity or NGO.
