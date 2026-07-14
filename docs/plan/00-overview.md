# TCGdex Ruby SDK — Implementation Plan Overview

## Goal

A Ruby SDK (gem `tcgdex`, constant `TCGdex`) for the TCGdex Pokémon TCG API
(https://tcgdex.dev), ported from the official Python SDK (primary reference) and
JavaScript SDK. Personal project for now: no publishing/release automation, but built to
proper gem standards (usable via Bundler `git:` source, semver from 0.1.0).

Target usage (this is the contract — keep it stable):

```ruby
tcgdex = TCGdex.new("en")                 # or TCGdex.new (defaults to "en")

card = tcgdex.card.get("swsh3-136")
card.name                                  # => "Furret"
card.local_id                              # => "136"
card.dex_id                                # => [162]
card.image_url(quality: :high, extension: :png)
# => "https://assets.tcgdex.net/en/swsh/swsh3/136/high.png"

cards = tcgdex.card.list(
  TCGdex::Query.new.contains(:name, "pika").gte(:hp, 60)
    .sort(:hp, :desc).paginate(page: 1, items_per_page: 20)
)                                          # => [TCGdex::CardBrief, ...]
cards.first.full_card                      # => TCGdex::Card (lazy fetch by id)

set = tcgdex.set.get("swsh3")
set.card_count.official                    # => 189
set.serie.full_serie                       # => TCGdex::Serie
set.card("136")                            # => TCGdex::Card via /sets/swsh3/136

tcgdex.type.list                           # => ["Colorless", "Darkness", ...]
tcgdex.rarity.get("Uncommon")              # => TCGdex::StringEndpoint (#name, #cards)
tcgdex.random.card                         # => TCGdex::Card

tcgdex.language = "fr"                     # per-instance config
tcgdex.cache_ttl = 600                     # seconds; cache is on by default (3600)
tcgdex.fetch("sets", "swsh3", "136")       # low-level escape hatch -> parsed Hash
```

## Confirmed decisions (user-approved — do not relitigate)

1. **Idiomatic Ruby**: snake_case attributes/methods; mechanical camelCase→snake_case JSON
   key mapping (`localId` → `local_id`). No camelCase aliases.
2. **Zero runtime dependencies**: stdlib `Net::HTTP` + `json` only.
3. **Tests**: RSpec + WebMock (unit) + VCR (integration cassettes).
4. **No publishing scaffolding**: no release workflow, no CODE_OF_CONDUCT/CONTRIBUTING.
   MIT license, proper gemspec, version 0.1.0.

Derived decisions: min Ruby **>= 3.2**; RuboCop + rubocop-rspec (dev-only);
`TCGdex` is a **class** (the client itself, like the JS/Python SDKs) that also serves as
the namespace for everything else (`TCGdex::Query`, `TCGdex::Card`, …).

## Architecture

```
tcgdex.gemspec
Gemfile / Rakefile / .rspec / .rubocop.yml
bin/console
lib/tcgdex.rb                  # requires everything; defines class TCGdex (entry point/client)
lib/tcgdex/version.rb          # TCGdex::VERSION = "0.1.0"
lib/tcgdex/errors.rb           # Error < StandardError; ServerError, NetworkError < Error
lib/tcgdex/cache.rb            # TCGdex::Cache — thread-safe in-memory TTL cache
lib/tcgdex/http.rb             # TCGdex::Http — Net::HTTP GET -> parsed JSON | nil
lib/tcgdex/query.rb            # TCGdex::Query — chainable filter/sort/pagination builder
lib/tcgdex/endpoint.rb         # TCGdex::Endpoint — generic #get(id) / #list(query)
lib/tcgdex/models/base.rb      # TCGdex::BaseModel — declarative attribute DSL
lib/tcgdex/models/card.rb        card_brief.rb  set.rb  set_brief.rb
lib/tcgdex/models/serie.rb       serie_brief.rb  string_endpoint.rb
lib/tcgdex/models/subs.rb      # CardVariants, CardAttack, CardAbility, CardItem,
                               # WeakRes, Legal, CardCount, CardCountBrief, Booster, Abbreviation
spec/spec_helper.rb
spec/fixtures/                 # static JSON for unit specs (seeded from docs/plan/fixtures/)
spec/cassettes/                # VCR cassettes (integration specs)
spec/tcgdex/...                # one spec file per lib file
docs/plan/                     # THIS PLAN — see handoff protocol below
```

Component responsibilities (details live in the milestone files):

- **`TCGdex` (class, lib/tcgdex.rb)** — holds config (`language`, `endpoint_url`
  default `https://api.tcgdex.net/v2`, `cache`, `cache_ttl`); exposes one `Endpoint`
  per resource plus `random` and the `fetch` escape hatch. Milestone 05.
- **`Http`** — single GET path used by everything; UA header, timeouts, error mapping,
  consults the cache. Milestone 02.
- **`Cache`** — Mutex-guarded Hash keyed by URL, monotonic-clock TTL, duck-typed
  (`#get(key)`, `#set(key, value, ttl)`) so users can plug their own; `cache = nil` disables.
  Milestone 02.
- **`Query`** — builds the exact REST params (see api-reference.md tables). Milestone 03.
- **`BaseModel` + models** — declarative attrs, camelCase→snake_case, nested casting,
  tolerant of unknown keys, `#to_h`, back-reference to the client for relationship
  helpers (`full_card`, `full_set`, `full_serie`, `Set#card`). Milestone 04.
- **`Endpoint`** — `(client, item_class, brief_class, path)`; `#get(id)` → full model or
  nil; `#list(query = nil)` → array of briefs (raw Strings/Integers for string endpoints).
  Milestone 05.

## Coding conventions

- `# frozen_string_literal: true` in every file.
- Zero runtime dependencies — if you're about to add one, stop and re-read decision 2.
- Naming: mechanical snake_case mapping from JSON keys, no exceptions, no pluralizing
  (`dexId` → `dex_id` even though the value is an array).
- Errors: 404/4xx → `nil`; 5xx → `TCGdex::ServerError`; transport failures →
  `TCGdex::NetworkError`; never leak raw `Net::HTTP` exceptions.
- Public API gets YARD docstrings (enforced in milestone 07, write as you go).
- Keep the JS/Python SDKs' spirit: small, no clever metaprogramming beyond the model DSL.
- Conventional-ish commits: `feat: ...`, `test: ...`, `docs: ...`, one commit per milestone
  minimum.

## Milestones & status

Work through these **in order** — each builds on the previous. Update this table (and the
checkboxes inside each milestone file) as you go; it is the single source of truth for
where the project stands.

| # | Milestone | File | Status | Commit |
|---|---|---|---|---|
| 1 | Gem scaffold & tooling | `01-gem-scaffold.md` | ☑ done (2026-07-14) | `79dd0d0` |
| 2 | HTTP client, cache, errors | `02-http-cache-errors.md` | ☑ done (2026-07-14) | `4c99149` |
| 3 | Query builder | `03-query-builder.md` | ☑ done (2026-07-14) | `53f0dd5` |
| 4 | Models | `04-models.md` | ☑ done (2026-07-14) | `1da2cd9` |
| 5 | Endpoints & client wiring | `05-endpoints-wiring.md` | ☑ done (2026-07-14) | |
| 6 | Integration tests (VCR) | `06-integration-tests.md` | ☐ not started | |
| 7 | Docs & polish | `07-docs-polish.md` | ☐ not started | |

Status values: `☐ not started` → `◐ in progress` → `☑ done (YYYY-MM-DD)`.

## Session handoff protocol

For any Claude session working on this repo:

1. Read this file, then `api-reference.md` (skim the gotchas at minimum).
2. Find the first milestone in the table above not marked done. Read its file fully.
3. If the previous session left a milestone `◐ in progress`, read its **Handoff notes**
   section first and continue from there.
4. Implement. Definition of done for every milestone: `bundle exec rake` green
   (RSpec + RuboCop) plus the milestone's own acceptance criteria.
5. Before ending: tick the milestone's checkboxes, update the status table above, add
   **Handoff notes** to the milestone file if stopping mid-way (what's done, what's not,
   any surprises), and commit.
6. If you discover the live API contradicts `api-reference.md`, fix the doc in the same
   commit — it must stay trustworthy.

Do not skip ahead: later milestones assume earlier interfaces exist exactly as specified.
If you must deviate from a specified interface, record the deviation and reason in the
milestone file's Handoff notes.
