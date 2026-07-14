# tcgdex-ruby-sdk

Ruby SDK (gem `tcgdex`, constant `TCGdex`) for the TCGdex Pokémon TCG API, ported from
the official Python/JavaScript SDKs. Zero runtime dependencies (Net::HTTP + json stdlib).

## Project status: PLANNED, BUILT MILESTONE-BY-MILESTONE

**Start here every session:** read `docs/plan/00-overview.md` (architecture, conventions,
milestone status table), then work the first unfinished milestone per its file
(`docs/plan/0N-*.md`). `docs/plan/api-reference.md` is the API ground truth — trust it
over memory, and update it if the live API disagrees. Follow the handoff protocol at the
bottom of `00-overview.md`: tick checkboxes, update the status table, leave Handoff notes
if stopping mid-milestone, commit per milestone.

## Commands

```bash
bundle install
bundle exec rake            # default task: rspec + rubocop — must be green before commit
bundle exec rspec spec/path/to/file_spec.rb   # single file
LIVE=1 bundle exec rspec spec/integration/live_smoke_spec.rb  # opt-in live API smoke
gem build tcgdex.gemspec
bin/console                 # IRB with the gem loaded
```

## Hard rules

- **Zero runtime dependencies.** Dev dependencies only (rspec/webmock/vcr/rubocop/yard).
- `# frozen_string_literal: true` in every Ruby file.
- Naming: mechanical camelCase→snake_case from JSON keys (`localId` → `local_id`,
  `dexId` → `dex_id`), no exceptions, no pluralizing.
- Error semantics: 404/4xx → `nil`; 5xx → `TCGdex::ServerError`; transport failures →
  `TCGdex::NetworkError`; never leak raw Net::HTTP exceptions.
- All HTTP goes through `TCGdex::Http`; responses cached (default TTL 3600s) — the API is
  free and unauthenticated, caching is our part of the deal.
- Tests offline by default (WebMock blocks network; VCR cassettes replay). Only cassette
  recording and `LIVE=1` may touch the network.
- Public API changes must keep the usage block in `docs/plan/00-overview.md` working —
  it is the contract (mirrored in README once milestone 07 lands).
