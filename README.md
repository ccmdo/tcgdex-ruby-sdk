# tcgdex

A zero-dependency Ruby SDK for the [TCGdex](https://tcgdex.dev) Pokémon Trading Card
Game API.

## What is TCGdex?

[TCGdex](https://tcgdex.dev) is a free, open-source, multilingual API for Pokémon TCG
data — cards, sets and series across 17 languages, with no authentication required.
This gem is an unofficial but faithful Ruby port of the official
[Python](https://github.com/tcgdex/python-sdk) and
[JavaScript](https://github.com/tcgdex/javascript-sdk) SDKs. It depends only on the
Ruby standard library (`Net::HTTP` + `json`) and caches responses by default, since
the API is free and unauthenticated.

## Installation

Not published to RubyGems. Add it to your `Gemfile` from Git:

```ruby
gem "tcgdex", git: "https://github.com/ccmdo/tcgdex-ruby-sdk"
```

Then `bundle install`. Or clone and install locally:

```bash
git clone https://github.com/ccmdo/tcgdex-ruby-sdk
cd tcgdex-ruby-sdk
bundle exec rake install
```

Requires Ruby >= 3.2.

## Quick start

```ruby
require "tcgdex"

tcgdex = TCGdex.new("en")                  # or TCGdex.new (defaults to "en")

card = tcgdex.card.get("swsh3-136")
card.name                                  # => "Furret"
card.local_id                              # => "136"
card.dex_id                                # => [162]
card.image_url(quality: :high, extension: :png)
# => "https://assets.tcgdex.net/en/swsh/swsh3/136/high.png"
card.pricing.cardmarket.trend              # => 0.1 (EUR)
card.pricing.tcgplayer.holofoil&.market_price
card.variants_detailed.first.type          # => "normal"

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

tcgdex.language = "fr"                      # per-instance config
tcgdex.cache_ttl = 600                     # seconds; cache is on by default (3600)
tcgdex.fetch("sets", "swsh3", "136")       # low-level escape hatch -> parsed Hash
```

Runnable versions of these live in [`examples/`](examples/) — run one with
`ruby -Ilib examples/basic.rb`.

## Endpoints

Every resource endpoint answers two calls: `#get(id)` returns one full model (or `nil`
if it does not exist), and `#list(query = nil)` returns an array of briefs (or of raw
values, for the index endpoints).

| Accessor | `#get(id)` returns | `#list` returns |
|---|---|---|
| `tcgdex.card` | `Card` | `[CardBrief]` |
| `tcgdex.set` | `Set` | `[SetBrief]` |
| `tcgdex.serie` | `Serie` | `[SerieBrief]` |
| `tcgdex.category` | `StringEndpoint` | `[String]` |
| `tcgdex.dex_id` | `StringEndpoint` | `[Integer]` |
| `tcgdex.energy_type` | `StringEndpoint` | `[String]` |
| `tcgdex.hp` | `StringEndpoint` | `[Integer]` |
| `tcgdex.illustrator` | `StringEndpoint` | `[String]` |
| `tcgdex.rarity` | `StringEndpoint` | `[String]` |
| `tcgdex.regulation_mark` | `StringEndpoint` | `[String]` |
| `tcgdex.retreat` | `StringEndpoint` | `[Integer]` |
| `tcgdex.stage` | `StringEndpoint` | `[String]` |
| `tcgdex.suffix` | `StringEndpoint` | `[String]` |
| `tcgdex.trainer_type` | `StringEndpoint` | `[String]` |
| `tcgdex.type` | `StringEndpoint` | `[String]` |
| `tcgdex.variant` | `StringEndpoint` | `[String]` |

Plus two extras:

- `tcgdex.random.card` / `.set` / `.serie` — a random full model.
- `tcgdex.fetch(*segments, query: nil)` — a low-level escape hatch that GETs an
  arbitrary path under the current language and returns the parsed JSON, for
  endpoints this SDK does not model yet.

A `StringEndpoint` (`#get` on one of the index endpoints) carries the matched value
(`#name`) and the cards that have it (`#cards`, an array of `CardBrief`):

```ruby
uncommon = tcgdex.rarity.get("Uncommon")
uncommon.name            # => "uncommon"  (the API echoes the value back lowercased)
uncommon.cards.first     # => #<TCGdex::CardBrief "...">
```

> **Note:** the live API currently returns an empty `cards` list for `type` and `hp`
> lookups; `rarity` and `illustrator` are populated. This is an API quirk, not an SDK bug.

## Querying

`TCGdex::Query` builds the API's filter/sort/pagination parameters. Every method takes
a field name (any JSON key of the full object, as a Symbol or String) and returns
`self`, so calls chain. Repeating a key is how you express a range.

| Method (aliases) | Effect | Example param |
|---|---|---|
| `contains` (`like`, `includes`) | partial, case-insensitive match | `name=pika` |
| `not_contains` (`not_like`) | laxist negation | `name=not:pika` |
| `equal` (`eq`) | strict equality (`\|`-separate to OR) | `name=eq:Furret` |
| `not_equal` (`neq`) | strict negation | `name=neq:Furret` |
| `greater_than` (`gt`) | numeric `>` | `hp=gt:50` |
| `greater_or_equal` (`gte`) | numeric `>=` | `hp=gte:50` |
| `less_than` (`lt`) | numeric `<` | `hp=lt:50` |
| `less_or_equal` (`lte`) | numeric `<=` | `hp=lte:50` |
| `null` | field is absent/null | `effect=null:` |
| `not_null` | field has a value | `effect=notnull:` |
| `sort(field, order)` | order by field (`:asc`/`:desc`) | `sort:field=hp&sort:order=DESC` |
| `paginate(page:, items_per_page:)` | page the results | `pagination:page=1&pagination:itemsPerPage=20` |

Wildcards pass through `contains`: `"fu*"` anchors to the start, `"*chu"` to the end.

```ruby
# Pikachu-ish cards with at least 60 HP, strongest first, first page of 20.
TCGdex::Query.new
  .contains(:name, "pika")
  .gte(:hp, 60)
  .sort(:hp, :desc)
  .paginate(page: 1, items_per_page: 20)

# An HP range (repeat the key), Colorless type, non-null illustrator.
TCGdex::Query.new
  .gte(:hp, 60)
  .lte(:hp, 120)
  .contains(:types, "Colorless")
  .not_null(:illustrator)

# Exactly Furret or Pikachu (pipe-separated OR on a strict match).
TCGdex::Query.new.equal(:name, "Furret|Pikachu")
```

## Images and assets

Image fields come back as base URLs without an extension; the SDK appends the format.
Card images take a quality; logos and symbols do not. `png` and `webp` are transparent,
`jpg` has a white background.

```ruby
card = tcgdex.card.get("swsh3-136")
card.image_url                                  # => ".../136/high.png"  (defaults)
card.image_url(quality: :low, extension: :webp) # => ".../136/low.webp"
card.image_data(quality: :low, extension: :jpg) # => binary String (not cached)

set = tcgdex.set.get("swsh3")
set.logo_url          # => "https://assets.tcgdex.net/en/swsh/swsh3/logo.png"
set.logo_url(:webp)   # => "...logo.webp"
set.symbol_url        # => "https://assets.tcgdex.net/univ/swsh/swsh3/symbol.png"

tcgdex.serie.get("swsh").logo_url  # series have a logo too
```

Qualities are `:high` / `:low`; extensions are `:png` / `:jpg` / `:webp`. An unknown
value raises `ArgumentError`. Any of these return `nil` when the resource has no image.

## Languages

Pass one of the 17 language codes to `TCGdex.new`, or set `tcgdex.language` later:

```
en  fr  es  es-mx  it  pt-br  pt-pt  de  nl  pl  ru  ja  ko  zh-tw  zh-cn  id  th
```

Not every card or set is translated into every language. A missing translation is a
`404`, which the SDK returns as `nil` — it is a normal outcome, not an error.

```ruby
%w[en fr de].each do |lang|
  tcgdex.language = lang
  puts tcgdex.card.get("swsh3-136").name   # => Furret / Fouinar / Wiesenior
end
```

## Configuration

All configuration is per instance; nothing is global.

```ruby
tcgdex = TCGdex.new(
  "en",
  endpoint_url: "https://api.tcgdex.net/v2",  # override the base URL if you must
  cache: TCGdex::Cache.new,                   # any object with #get/#set; nil disables
  cache_ttl: 3600                             # seconds a cached response stays fresh
)

tcgdex.language = "ja"    # switch language at any time
tcgdex.cache_ttl = 600    # shorten the TTL
tcgdex.cache = nil        # disable caching entirely
```

The default cache is a thread-safe, in-memory, per-URL TTL store. It is deliberately
simple: no size limit and no eviction, so a long-lived process hitting many distinct
URLs grows it unboundedly — call `tcgdex.cache.clear` periodically, or plug in your own.
Any object responding to `#get(key)` and `#set(key, value, ttl)` works. Values are the
raw JSON response Strings (re-parsed on every hit, so results are always safe to
mutate), which makes a serializing store like Redis a drop-in fit:

```ruby
tcgdex.cache = MyRedisBackedCache.new   # duck-typed; must answer #get / #set
```

## Error handling

The SDK never leaks raw `Net::HTTP` exceptions. Outcomes map like this:

| Situation | Result |
|---|---|
| Missing / untranslated resource (404), or other non-2xx, non-5xx | `nil` |
| Server error (5xx) | raises `TCGdex::ServerError` (`#status`, `#body`) |
| DNS / timeout / connection / TLS failure | raises `TCGdex::NetworkError` (`#cause` preserved) |

Redirects (3xx) are followed automatically, up to 5 hops; a longer chain raises
`TCGdex::NetworkError`.

Both error classes inherit `TCGdex::Error`, so one rescue catches everything the SDK
raises:

```ruby
begin
  card = tcgdex.card.get("swsh3-136")
  return puts("no such card") if card.nil?   # 404 -> nil, check for it
  puts card.name
rescue TCGdex::ServerError => e
  warn "TCGdex is having trouble (#{e.status})"
rescue TCGdex::NetworkError => e
  warn "could not reach TCGdex: #{e.message}"
end
```

## Development

```bash
bundle install
bundle exec rake            # default: RSpec + RuboCop — must be green
bundle exec rspec spec/tcgdex/query_spec.rb   # a single file
```

The suite runs fully offline: WebMock blocks the network for unit specs, and the
integration specs replay recorded [VCR](https://github.com/vcr/vcr) cassettes under
`spec/cassettes/`. Only re-recording a cassette or the opt-in live smoke test touches
the network:

```bash
LIVE=1 bundle exec rspec spec/integration/live_smoke_spec.rb   # hits the real API
```

## License

Released under the [MIT License](LICENSE).

This is an unofficial SDK. TCGdex is a project by the TCGdex team
(<https://tcgdex.dev>). Pokémon and all related trademarks and card data are
© Nintendo, Game Freak and The Pokémon Company; this project is not affiliated with,
endorsed, or sponsored by any of them.
