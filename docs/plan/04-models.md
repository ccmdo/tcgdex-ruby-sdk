# Milestone 04 — Models

## Objective

All data models: `TCGdex::BaseModel` (declarative attribute DSL) plus `Card`, `CardBrief`,
`Set`, `SetBrief`, `Serie`, `SerieBrief`, `StringEndpoint` and the sub-structs. Built from
parsed JSON hashes, tolerant of unknown keys, with image-URL helpers and relationship
helpers. Unit-tested against the static fixtures in `docs/plan/fixtures/` (copy the ones
you use into `spec/fixtures/`).

**The complete field tables (JSON key → ruby attr → type) live in `api-reference.md` —
they are the spec for this milestone. Follow them exactly, including the live-only fields
(`variants_detailed`, `pricing`, `updated`, serie `first_set`/`last_set`/`release_date`,
set `abbreviation` singular).**

## Prerequisites

Milestones 01–02 (Http is needed for image download helpers). Read the **Model field
tables** and **Gotchas** sections of `api-reference.md` in full.

## Design contract

### `TCGdex::BaseModel` (lib/tcgdex/models/base.rb)

```ruby
class TCGdex
  class BaseModel
    # DSL — used by subclasses:
    #   attribute :local_id                        # reads json key "localId" (auto camelize)
    #   attribute :hp                              # reads "hp"
    #   attribute :set, model: SetBrief            # nested cast
    #   attribute :attacks, model: CardAttack, array: true
    #   attribute :variants_detailed, key: "variants_detailed"  # explicit key when not camelCase
    def self.attribute(name, key: nil, model: nil, array: false)

    def initialize(data, client: nil)   # data = parsed JSON Hash; client = TCGdex instance or nil
    attr_reader :client                 # back-reference for relationship helpers
    def to_h                            # the raw parsed Hash (everything, incl. unmodeled keys)
  end
end
```

Implementation notes:

- `attribute` derives the JSON key by camelizing the attr name (`local_id` → `"localId"`)
  unless `key:` is given. Keep the camelize helper private and dumb
  (`name.to_s.gsub(/_([a-z])/) { $1.upcase }`) — the mapping is mechanical by convention
  (00-overview.md), so round-tripping is trivial.
- `attribute` defines a reader method that lazily (or eagerly in the constructor — eager is
  simpler, pick eager) pulls from the data hash and casts: `model:` wraps a Hash in the
  model class (passing `client:` down — this is how nested models can lazy-load, mirroring
  the Python SDK's `_from_dict` sdk propagation); `array: true` maps over the value.
  Missing/nil keys → nil, never raise.
- Unknown JSON keys: ignored by the DSL by design, but still visible via `#to_h`.
- Equality: `==` comparing class + `to_h` (cheap, handy in specs). Add `#inspect` that
  shows class + id/name only — full card hashes are huge and will spam consoles.
- No `method_missing`, no OpenStruct.

### Models and their extras (beyond the field tables)

| Class (file) | Extra methods |
|---|---|
| `Card` (card.rb) | `image_url(quality: :high, extension: :png)` → `"#{image}/#{quality}.#{extension}"` or nil; `image_data(quality:, extension:)` → binary String via `client.http.get_raw`* or nil; `full_set` → `client.set.get(set.id)` |
| `CardBrief` (card_brief.rb) | `image_url`/`image_data` (same as Card); `full_card` → `client.card.get(id)` |
| `Set` (set.rb) | `logo_url(extension = :png)`, `symbol_url(extension = :png)` (`"#{base}.#{ext}"`); `card(local_id)` → full Card via `/sets/{id}/{local_id}` (client-backed — see sequencing note below) |
| `SetBrief` (set_brief.rb) | `logo_url`, `symbol_url`; `full_set` → `client.set.get(id)` |
| `Serie` (serie.rb) | `logo_url(extension = :png)` |
| `SerieBrief` (serie_brief.rb) | `logo_url`; `full_serie` → `client.serie.get(id)` |
| `StringEndpoint` (string_endpoint.rb) | none (`name`, `cards` array of CardBrief) |

*Sequencing note*: relationship helpers (`full_card`, `Set#card`, `image_data`) call into
the client/endpoints, which don't exist until milestone 05. Implement them now as written
— specs stub the client with an RSpec double (`instance_double`-style: `client.card.get`)
— and milestone 05 makes them real. If `client` is nil, raise
`TCGdex::Error, "model is not attached to a TCGdex client"` (nil would silently hide bugs).
`image_url`-style helpers need no client.

For `image_data`: add `Http#get_raw(url)` in this milestone (returns raw body String for
2xx, nil otherwise, same error mapping, **no caching** of binaries) — small addition to
milestone 02's class, with a WebMock spec.

Quality/extension args: accept Symbol or String; validate against
`%w[high low]` / `%w[png jpg webp]` and raise `ArgumentError` otherwise (typo-catching is
worth more than flexibility here).

### Sub-structs (models/subs.rb, all `< BaseModel`)

`CardVariants`, `CardAttack`, `CardAbility`, `CardItem`, `WeakRes`, `Legal`, `CardCount`,
`CardCountBrief`, `Booster`, `Abbreviation` — fields per the api-reference.md table.
`variants_detailed` and `pricing`: leave as **raw Hashes** in 0.1 (stretch goal: typed
`VariantDetailed` with `pricing` kept raw — hyphenated keys like `"reverse-holofoil"` and
`"avg-holo"` make full typing not worth it yet).

## Tasks

- [ ] Copy needed fixtures from `docs/plan/fixtures/` into `spec/fixtures/` (keep names).
- [ ] `Http#get_raw` + spec (see above).
- [ ] `base.rb` + `spec/tcgdex/models/base_spec.rb` (test the DSL itself with a throwaway
      subclass: camelize mapping, explicit key, nested model, array cast, unknown keys
      ignored, `to_h`, nil client, equality).
- [ ] `subs.rb`, then the seven model files, requiring order handled in `lib/tcgdex.rb`
      (base → subs → briefs → full models).
- [ ] Specs per model, driven by the fixtures: `card_full.json` exercises nearly every
      Card attr (attacks, weaknesses, variants, legal, set brief, dex_id, live-only fields);
      `set_full_trimmed.json`, `serie_full_trimmed.json`, `sets_list_trimmed.json`,
      `series_list_trimmed.json` (note the logo-less `misc` serie), `cards_list_page.json`
      (pre-encoded id `exu-%3F`), `illustrator_item_trimmed.json`.
      Assert `image_url` string composition and the ArgumentError validations.
      Relationship helpers: client double receives expected call; nil client raises.
- [ ] YARD docstrings (at least class-level + non-obvious methods).
- [ ] Commit: `feat: add data models with declarative attribute mapping`.

## Acceptance criteria

`bundle exec rake` green, and:

```ruby
card = TCGdex::Card.new(JSON.parse(File.read("spec/fixtures/card_full.json")))
card.name                  # => "Furret"
card.dex_id                # => [162]
card.set.card_count.total  # => 201
card.attacks[1].damage     # => 90
card.legal.expanded        # => true
card.image_url(quality: :low, extension: :webp)
# => "https://assets.tcgdex.net/en/swsh/swsh3/136/low.webp"
card.to_h.key?("variants_detailed")  # => true (unmodeled data still reachable)
```

## Out of scope

Endpoint classes and real client wiring (milestone 05); typed pricing models.

## Handoff notes

(fill in only if stopping mid-milestone)
