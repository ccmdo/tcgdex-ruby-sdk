# Milestone 08 — Typed pricing & detailed variants

Promote `Card#pricing` and `Card#variants_detailed` from raw Hashes (a 0.1 stretch-goal
deferral, see `04-models.md`) to typed models, matching the newer official SDKs.

**Model sources compared** (2026-07-15): the Kotlin SDK
(`java-sdk`: `Pricing`, `PricingCardMarket`, `PricingTcgPlayer`, `PricingTcgPlayerVariant`)
and the Swift SDK (`swift-sdk/Sources/TCGDex/TCGDex.swift`: adds `CardVariantsDetailed`
fields `subType`/`stamp`/`foil`). Live API data (`spec/fixtures/card_full.json`, recorded
2026-07-14) additionally carries `cardmarket.idProduct` and tcgplayer's per-variant
`productId`, which **neither** official SDK models. We model the union; see
`api-reference.md` for the resulting field tables.

Decisions:

- Flat classes in `lib/tcgdex/models/pricing.rb`, subs.rb idiom: `Pricing`,
  `PricingCardmarket`, `PricingTcgplayer`, `PricingTcgplayerVariant`, `VariantDetailed`.
- Hyphenated/digit-led JSON keys (`"avg-holo"`, `"1st-edition-holofoil"`, …) map via the
  existing `attribute key:` override — the reason these stayed raw in 0.1 is gone.
- Kotlin's `holoFoil` property has no `@SerializedName` and would read a `"holoFoil"` key
  that the API never sends — treated as an upstream bug; the live key is `"holofoil"`.
- Raw payloads stay reachable through `#to_h` (BaseModel guarantee), so 0.1-style hash
  access still has an escape hatch.
- Version bumped to 0.2.0: `card.pricing["cardmarket"]` no longer works — breaking for
  raw-Hash callers, though the gem was never published.

Checklist:

- [x] `lib/tcgdex/models/pricing.rb` with the five models; required from `lib/tcgdex.rb`
      and `card.rb`
- [x] `Card#pricing` → `model: Pricing`; `Card#variants_detailed` → `model:
      VariantDetailed, array: true` (key stays `"variants_detailed"`, snake_case live-only)
- [x] Specs: `pricing_spec.rb` + `variant_detailed_spec.rb` (every key override,
      nil-tolerance, nested pricing); `card_spec.rb` live-only section retyped
- [x] `api-reference.md` Pricing/VariantDetailed tables updated from live data + both SDKs
- [x] Usage contract (`00-overview.md`) + README gain pricing lines; CHANGELOG 0.2.0;
      `VERSION = "0.2.0"`
- [x] `bundle exec rake` green

Acceptance: fixture card answers `pricing.cardmarket.avg_holo == 0.31`,
`pricing.tcgplayer.reverse_holofoil.market_price == 0.36`,
`variants_detailed.first.pricing.cardmarket.trend == 0.1`.
