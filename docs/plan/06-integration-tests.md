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
- [ ] `card.get("swsh3-136")` → name "Furret", hp 110, attacks parsed, `set.id` "swsh3"
- [ ] `card.list(paginated)` → CardBriefs with id/local_id/name
- [ ] `set.get("swsh3")` → card_count.official 189, cards present, serie brief, legal
- [ ] `set.list(paginated)` → SetBriefs with card_count
- [ ] `serie.get("swsh")` → sets list, first_set/last_set live-only fields tolerated
- [ ] `serie.list(paginated)` → SerieBriefs (include the logo-less `misc` check if present in page)
- [ ] `set.card("136")` on the swsh3 Set → full Card via `/sets/swsh3/136`
- [ ] relationship traversal: `card.list(...).first.full_card` → full Card;
      `set brief → full_set`; `serie brief → full_serie`

String endpoints — for EACH of the 13 (`category, dex_id, energy_type, hp, illustrator,
rarity, regulation_mark, retreat, stage, suffix, trainer_type, type, variant`):
- [ ] `.list` → non-empty raw array (Integer values for hp/dex_id/retreat, else String)
- [ ] one `.get(value)` per endpoint → StringEndpoint with echoed name
      (assert non-empty `cards` only for rarity/illustrator)

Query filters (recorded against `/cards`):
- [ ] `equal(:name, "Furret")` → every result named Furret
- [ ] `not_equal(:name, "Furret")` + `contains(:name, "furret")` → laxist-vs-strict sanity
- [ ] `gte(:hp, 300)` paginated → all hp >= 300 (needs full-card check? briefs lack hp —
      assert non-empty result only; the API filters server-side)
- [ ] `sort(:hp, :desc)` + paginate → results ordered (spot-check via full card fetch is
      overkill; assert request URL params recorded correctly in cassette instead)
- [ ] `null(:effect)` smoke — non-empty

Misc:
- [ ] French: `TCGdex.new("fr").card.get("swsh3-136")` → French name ("Fouinar")
- [ ] `random.card` → valid Card (assert shape not content; `record: :once` pins it)
- [ ] 404: `card.get("nonexistent-999")` → nil (cassette records the 404)
- [ ] escape hatch: `fetch("sets", "swsh3", "136")` → Hash with `"name" => "Furret"`

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

- [ ] VCR config + support file.
- [ ] Implement matrix above (group into a few spec files: `cards_spec`, `sets_series_spec`,
      `string_endpoints_spec` (table-driven loop over the 13), `query_spec`, `misc_spec`).
- [ ] Record cassettes (live network needed once); commit them.
- [ ] Fix any model/API mismatches surfaced — update `api-reference.md` in the same commit
      if the doc was wrong.
- [ ] Live smoke spec.
- [ ] Commit: `test: add VCR-backed integration suite and live smoke test`.

## Acceptance criteria

- `bundle exec rake` green **with network disabled** (WebMock blocks; cassettes replay).
- `LIVE=1 bundle exec rspec` green with network.
- `spec/cassettes/` committed; no cassette over ~100 KB (paginate harder if so).

## Out of scope

README/examples/CHANGELOG (milestone 07); performance/benchmarks.

## Handoff notes

(fill in only if stopping mid-milestone)
