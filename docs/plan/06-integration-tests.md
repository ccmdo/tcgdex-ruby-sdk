# Milestone 06 — Integration tests (VCR)

## Objective

Recorded end-to-end coverage of every endpoint type against real API responses, mirroring
the Python SDK's test matrix (~38 vcrpy fixtures), plus an opt-in live smoke test. This is
where we find out the API's real shapes disagree anywhere with our models.

## Prerequisites

Milestones 01–05 complete (`bundle exec rake` green).

## VCR setup

In `spec/spec_helper.rb` (or a `spec/support/vcr.rb` required from it):

```ruby
VCR.configure do |c|
  c.cassette_library_dir = "spec/cassettes"
  c.hook_into :webmock
  c.default_cassette_options = { record: :once, match_requests_on: %i[method uri] }
  c.configure_rspec_metadata!    # use via `it "...", :vcr do`
end
```

- No secrets to filter (unauthenticated API).
- Recording requires live network: run once locally to create cassettes, commit them.
  With `record: :once`, CI/replays never touch the network.
- Keep cassettes small: always paginate list requests in these specs
  (`itemsPerPage: 2`-ish); prefer `rarities`/`illustrators` for string-endpoint item
  lookups with populated cards (api-reference.md gotcha 5 — `types`/`hp` items currently
  return empty `cards`; still record one to pin the shape, but don't assert non-empty).

## Test matrix (`spec/integration/` — port of Python's tests.py)

Card / Set / Serie:
- [x] `card.get("swsh3-136")` → name "Furret", hp 110, attacks parsed, `set.id` "swsh3"
- [x] `card.list(paginated)` → CardBriefs with id/local_id/name
- [x] `set.get("swsh3")` → card_count.official 189, cards present, serie brief, legal
- [x] `set.list(paginated)` → SetBriefs with card_count
- [x] `serie.get("swsh")` → sets list, first_set/last_set live-only fields tolerated
- [x] `serie.list(paginated)` → SerieBriefs (include the logo-less `misc` check if present in page)
- [x] `set.card("136")` on the swsh3 Set → full Card via `/sets/swsh3/136`
- [x] relationship traversal: `card.list(...).first.full_card` → full Card;
      `set brief → full_set`; `serie brief → full_serie`

String endpoints — for EACH of the 13 (`category, dex_id, energy_type, hp, illustrator,
rarity, regulation_mark, retreat, stage, suffix, trainer_type, type, variant`):
- [x] `.list` → non-empty raw array (Integer values for hp/dex_id/retreat, else String)
- [x] one `.get(value)` per endpoint → StringEndpoint with echoed name
      (assert non-empty `cards` only for rarity/illustrator)

Query filters (recorded against `/cards`):
- [x] `equal(:name, "Furret")` → every result named Furret
- [x] `not_equal(:name, "Furret")` + `contains(:name, "furret")` → laxist-vs-strict sanity
- [x] `gte(:hp, 300)` paginated → all hp >= 300 (needs full-card check? briefs lack hp —
      assert non-empty result only; the API filters server-side)
- [x] `sort(:hp, :desc)` + paginate → results ordered (spot-check via full card fetch is
      overkill; assert request URL params recorded correctly in cassette instead)
- [x] `null(:effect)` smoke — non-empty

Misc:
- [x] French: `TCGdex.new("fr").card.get("swsh3-136")` → French name ("Fouinar")
- [x] `random.card` → valid Card (assert shape not content; `record: :once` pins it)
- [x] 404: `card.get("nonexistent-999")` → nil (cassette records the 404)
- [x] escape hatch: `fetch("sets", "swsh3", "136")` → Hash with `"name" => "Furret"`

## Live smoke test (opt-in, no cassette)

`spec/integration/live_smoke_spec.rb`, guarded:

```ruby
RSpec.describe "live API smoke", if: ENV["LIVE"] == "1" do
  around { |ex| VCR.turned_off { WebMock.allow_net_connect!; ex.run; WebMock.disable_net_connect! } }
  it "fetches Furret for real" do
    expect(TCGdex.new.card.get("swsh3-136").name).to eq("Furret")
  end
end
```

Run manually: `LIVE=1 bundle exec rspec spec/integration/live_smoke_spec.rb`.

## Tasks

- [x] VCR config + support file.
- [x] Implement matrix above (group into a few spec files: `cards_spec`, `sets_series_spec`,
      `string_endpoints_spec` (table-driven loop over the 13), `query_spec`, `misc_spec`).
- [x] Record cassettes (live network needed once); commit them.
- [x] Fix any model/API mismatches surfaced — update `api-reference.md` in the same commit
      if the doc was wrong.
- [x] Live smoke spec.
- [x] Commit: `test: add VCR-backed integration suite and live smoke test`.

## Acceptance criteria

- `bundle exec rake` green **with network disabled** (WebMock blocks; cassettes replay).
- `LIVE=1 bundle exec rspec` green with network.
- `spec/cassettes/` committed; no cassette over ~100 KB (paginate harder if so).

## Out of scope

README/examples/CHANGELOG (milestone 07); performance/benchmarks.

## Handoff notes

Milestone complete. 52 cassettes recorded on the first live run — **every model parsed
cleanly, so `api-reference.md` needed no corrections.** Both acceptance checks pass:
`bundle exec rake` green offline (WebMock blocks, cassettes replay), and
`LIVE=1 bundle exec rspec spec/integration/live_smoke_spec.rb` green with network.

Notes for milestone 07 / future recording:

- **Cassette values were chosen for small card counts** (string-endpoint item lookups return
  the *entire* card list — pagination does not shrink them). Largest cassette is 66 KB
  (`categories/Energy`, the smallest of the three categories); all others well under. If you
  re-record, keep these values: regulation-mark `None` (2 cards) and suffix `Legend` (18) —
  the obvious picks (`H`, `EX`) blow past 100 KB.
- **Latent bug found and fixed in `Http` (was milestone 02):** the `fetch` escape hatch built
  URLs with raw values, so `fetch("illustrators", "tetsuya koizumi")` raised
  `URI::InvalidURIError`. `Http#parse_uri` now escapes spaces (idempotent with `Endpoint`'s
  own escaping) and wraps any remaining `URI::InvalidURIError` in `TCGdex::Error`. Unit-specced
  in `http_spec.rb`. `Endpoint#get` still escapes ids itself; this just makes the low-level
  path robust too.
- To re-record a single interaction: delete its file under `spec/cassettes/` and run that
  example with a live network; `record: :once` re-records only what is missing.
- RuboCop: `spec/integration/**/*` excluded from `RSpec/DescribeClass` (they describe a
  behaviour string, not a class).
