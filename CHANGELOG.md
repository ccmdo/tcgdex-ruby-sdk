# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-07-15

### Changed

- **Breaking**: `Card#pricing` and `Card#variants_detailed` are now typed models
  instead of raw Hashes. Hyphenated and digit-led JSON keys map to snake_case
  readers: `pricing.cardmarket.avg_holo` (`"avg-holo"`),
  `pricing.tcgplayer.first_edition_holofoil` (`"1st-edition-holofoil"`), and so on.
  The raw payload remains available through `#to_h`.

### Added

- Pricing models `TCGdex::Pricing`, `PricingCardmarket`, `PricingTcgplayer` and
  `PricingTcgplayerVariant`, covering Cardmarket (`avg`/`low`/`trend` and their
  1/7/30-day and `*_holo` variants, `id_product`) and TCGplayer (per-printing
  `low_price`/`mid_price`/`high_price`/`market_price`/`direct_low_price`,
  `product_id`) — including the `idProduct`/`productId` fields the official
  Kotlin and Swift SDKs do not model.
- `TCGdex::VariantDetailed` for `Card#variants_detailed`: `type`, `size`,
  `variant_id`, `sub_type`, `stamp`, `foil`, and its own nested `pricing`.

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
- HTTP transport over `Net::HTTP` with a `User-Agent` header, timeouts,
  redirect following (up to 5 hops), and error mapping: 404/other non-2xx →
  `nil`; 5xx → `TCGdex::ServerError`; transport failures → `TCGdex::NetworkError`
  (both under `TCGdex::Error`).
- Thread-safe in-memory TTL cache (default 3600s), pluggable via the
  `#get`/`#set` duck type, disableable with `cache = nil`. Values are stored as
  raw JSON strings and re-parsed per hit, so every result is a fresh object —
  mutating one cannot corrupt later reads — and custom caches only ever see
  serializable Strings.

[0.1.0]: https://github.com/ccmdo/tcgdex-ruby-sdk/releases/tag/v0.1.0
