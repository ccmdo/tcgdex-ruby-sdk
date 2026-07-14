# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-07-15

Initial release: a zero-runtime-dependency Ruby SDK for the
[TCGdex](https://tcgdex.dev) Pokémon TCG API, ported from the official Python and
JavaScript SDKs.

### Added

- `TCGdex` client with per-instance configuration: `language`, `endpoint_url`,
  `cache` and `cache_ttl`.
- Resource endpoints with `#get(id)` and `#list(query)`: `card`, `set`, `serie`,
  plus the string/integer index endpoints `category`, `dex_id`, `energy_type`, `hp`,
  `illustrator`, `rarity`, `regulation_mark`, `retreat`, `stage`, `suffix`,
  `trainer_type`, `type` and `variant`.
- `random.card`, `random.set`, `random.serie`, and a low-level `fetch` escape hatch.
- `TCGdex::Query`, a chainable builder for the API's filtering, sorting and
  pagination parameters (`contains`, `equal`, `gte`/`lte`, `null`/`not_null`,
  `sort`, `paginate`, and aliases).
- Data models (`Card`, `Set`, `Serie` and their briefs, `StringEndpoint`, and the
  nested sub-structures) with mechanical camelCase→snake_case attribute mapping,
  tolerance of unknown JSON keys, and `#to_h` access to the raw payload.
- Relationship helpers that lazily hydrate resumes: `CardBrief#full_card`,
  `SetBrief#full_set`, `SerieBrief#full_serie`, `Card#full_set`, `Set#card`.
- Image/asset URL builders: `Card#image_url` (quality + extension), `Set#logo_url`
  / `#symbol_url`, `Serie#logo_url`, plus `#image_data` for binary downloads.
- HTTP transport over `Net::HTTP` with a `User-Agent` header, timeouts, and error
  mapping: 404/other non-2xx → `nil`; 5xx → `TCGdex::ServerError`; transport
  failures → `TCGdex::NetworkError` (both under `TCGdex::Error`).
- Thread-safe in-memory TTL cache (default 3600s), pluggable via the
  `#get`/`#set` duck type, disableable with `cache = nil`.

[0.1.0]: https://github.com/ccmdo/tcgdex-ruby-sdk/releases/tag/v0.1.0
