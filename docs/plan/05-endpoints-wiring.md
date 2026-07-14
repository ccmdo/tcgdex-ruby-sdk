# Milestone 05 — Endpoints & client wiring

## Objective

The public SDK surface: generic `TCGdex::Endpoint`, the `TCGdex` client class wiring all
16 endpoints + `random` + the `fetch` escape hatch, config (language / endpoint_url /
cache), and the `Set#card(local_id)` + `image_data` helpers becoming real. After this
milestone the usage block at the top of `00-overview.md` works end-to-end (unit-tested
with WebMock; live verification is milestone 06).

## Prerequisites

Milestones 01–04. The usage block in `00-overview.md` is the contract; re-read it now.

## Design contract

### `TCGdex::Endpoint` (lib/tcgdex/endpoint.rb)

```ruby
class TCGdex
  class Endpoint
    # client:      TCGdex instance
    # item_class:  model for GET /{path}/{id} (Card, Set, Serie, StringEndpoint)
    # brief_class: model for GET /{path} list items, or nil for raw values (String/Integer lists)
    # path:        URL segment ("cards", "dex-ids", ...)
    def initialize(client, item_class, brief_class, path)

    def get(id)            # full item model, or nil (404 etc.)
    def list(query = nil)  # array of brief models, or raw array for string endpoints
  end
end
```

- `get(id)`: URL = `{client.endpoint_url}/{client.language}/{path}/{escaped_id}` where
  escaping replaces **spaces only** with `%20` (api-reference.md gotcha 2: IDs can be
  pre-encoded — do not URI-escape the whole segment). Wrap response:
  `item_class.new(data, client:)` — nil passes through.
- `list(query)`: URL = `.../{path}` + (`"?" + query.to_s` if query given and non-empty).
  If `brief_class` is nil, return the parsed array as-is (types/hp/etc. return raw
  Strings/Integers). Otherwise map each element through `brief_class.new(el, client:)`.
- Language: `client.language.to_s` (so a future Symbol/enum works; `"en"` for now).

### `TCGdex` client (lib/tcgdex.rb)

```ruby
tcgdex = TCGdex.new("en")            # positional lang, default "en"
tcgdex.language      # "en"          — attr_accessor
tcgdex.endpoint_url  # "https://api.tcgdex.net/v2" — attr_accessor, no trailing slash
tcgdex.cache_ttl     # 3600          — delegates to http
tcgdex.cache         # Cache         — delegates to http; assign custom duck-type or nil to disable
tcgdex.http          # Http instance (internal-ish but public for get_raw/model helpers)
```

Endpoint wiring (memoized readers, one line each):

| Reader | item_class | brief_class | path |
|---|---|---|---|
| `card` | `Card` | `CardBrief` | `cards` |
| `set` | `Set` | `SetBrief` | `sets` |
| `serie` | `Serie` | `SerieBrief` | `series` |
| `category` | `StringEndpoint` | nil | `categories` |
| `dex_id` | `StringEndpoint` | nil | `dex-ids` |
| `energy_type` | `StringEndpoint` | nil | `energy-types` |
| `hp` | `StringEndpoint` | nil | `hp` |
| `illustrator` | `StringEndpoint` | nil | `illustrators` |
| `rarity` | `StringEndpoint` | nil | `rarities` |
| `regulation_mark` | `StringEndpoint` | nil | `regulation-marks` |
| `retreat` | `StringEndpoint` | nil | `retreats` |
| `stage` | `StringEndpoint` | nil | `stages` |
| `suffix` | `StringEndpoint` | nil | `suffixes` |
| `trainer_type` | `StringEndpoint` | nil | `trainer-types` |
| `type` | `StringEndpoint` | nil | `types` |
| `variant` | `StringEndpoint` | nil | `variants` |

Plus:

- `random` — memoized small object (Struct or private class `Random`) with `#card`, `#set`,
  `#serie` hitting `random/card|set|serie` and wrapping in the full model classes.
- `fetch(*path_segments, query: nil)` — low-level escape hatch:
  `http.get("#{endpoint_url}/#{language}/#{path_segments.join('/')}" + query_string)`,
  returns the parsed JSON as-is (Hash/Array), nil on 404. This is how users reach future
  API endpoints the SDK doesn't model yet. `query:` accepts a `Query` or nil.
- `Set#card(local_id)` (already stubbed in milestone 04) becomes:
  `client.fetch("sets", id, local_id)` wrapped in `Card.new(data, client:)` — or cleaner,
  add `Endpoint#get_nested(id, sub_id)`; pick whichever reads better, document choice here.

Constructor builds one `Http` (so cache is shared across endpoints). `language=` accepts
String/Symbol, stored as String. Changing `endpoint_url`/`language` affects subsequent
requests (endpoints read from client at request time — do not bake URLs at wiring time;
note the memoized Endpoint objects hold only `path`).

## Tasks

- [ ] `lib/tcgdex/endpoint.rb` + `spec/tcgdex/endpoint_spec.rb` (WebMock: URL construction
      incl. language and space-escaping; 404 → nil; query appended; brief mapping;
      raw list passthrough for nil brief_class; client back-ref present on returned models).
- [ ] `TCGdex` client class in `lib/tcgdex.rb` + `spec/tcgdex_spec.rb` grows:
      all 16 readers return Endpoints with correct paths (table-driven spec);
      `random.card/set/serie`; `fetch` joins paths and passes Query; config accessors
      delegate correctly; two clients don't share caches unless told to.
- [ ] Make milestone-04 relationship helpers real: green without RSpec doubles —
      WebMock-stub `full_card`, `SetBrief#full_set`, `Set#card`, `CardBrief#image_data`.
- [ ] Wire `Set#card` per the design decision above; record the choice here.
- [ ] YARD on all public methods; update README later (milestone 07), not now.
- [ ] Commit: `feat: wire client, endpoints, random and fetch escape hatch`.

## Acceptance criteria

`bundle exec rake` green. With WebMock stubs, the full usage block from `00-overview.md`
executes line-for-line. Sanity check manually (allowed to hit the live API once here):

```bash
ruby -Ilib -e 'require "tcgdex"; c = TCGdex.new; card = c.card.get("swsh3-136");
  puts card.name; puts card.image_url; puts c.type.list.inspect'
# Furret / https://assets.tcgdex.net/en/swsh/swsh3/136/high.png / ["Colorless", ...]
```

## Out of scope

VCR cassettes and the full integration matrix (milestone 06); README/examples (07).

## Handoff notes

(fill in only if stopping mid-milestone)
