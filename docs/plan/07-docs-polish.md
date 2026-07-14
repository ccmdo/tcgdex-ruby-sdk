# Milestone 07 — Docs & polish

## Objective

Ship-quality finish for a 0.1.0: README, YARD coverage on the public API, runnable
examples, CHANGELOG, and a final QA pass. After this milestone the plan is complete and
`docs/plan/` becomes historical record.

## Prerequisites

Milestones 01–06 (everything green, cassettes committed).

## Tasks

### README.md

- [ ] Structure:
  1. Title + one-liner + badge-free (no CI badge needed unless CI exists)
  2. What is TCGdex (one paragraph, link https://tcgdex.dev; note unofficial-but-faithful
     port of the official JS/Python SDKs)
  3. Installation — Bundler `git:` source (not published to RubyGems):
     `gem "tcgdex", git: "https://github.com/<owner>/tcgdex-ruby-sdk"` and plain clone + `rake install` alternative
  4. Quick start — the usage block from `00-overview.md` (keep them in sync; it is the contract)
  5. Endpoints table (the 16 + random + fetch)
  6. Querying — method table condensed from `03-query-builder.md`, with 3 realistic examples
  7. Images/assets — quality/extension rules + example URLs
  8. Languages — the 17 codes; note 404 = untranslated content
  9. Configuration — language, endpoint_url, cache/cache_ttl, disabling cache, plugging
     a custom cache (duck type `get`/`set`)
  10. Error handling — nil vs ServerError vs NetworkError, with a rescue example
  11. Development — `bundle exec rake`, recording cassettes, `LIVE=1` smoke
  12. License (MIT) + credits (TCGdex project, data (c) Pokémon/Nintendo disclaimers as in
      upstream READMEs)
- [ ] Every code sample in the README must be executed once (copy into `bin/console` or a
      scratch script) — no aspirational examples.

### YARD

- [ ] `yard doc --no-cache` runs clean; spot-check `yard stats --list-undoc` — public
      methods 100% documented (private helpers exempt).
- [ ] `@example` tags on: `TCGdex.new`, `Endpoint#get/#list`, `Query` class doc,
      `Card#image_url`.
- [ ] Add `.yardopts`: `--markup markdown lib/**/*.rb`.

### examples/

- [ ] `examples/basic.rb` — fetch a card, print name/hp/attacks, image URL.
- [ ] `examples/search.rb` — Query with filters + pagination, iterate briefs, hydrate one.
- [ ] `examples/languages.rb` — same card in en/fr/de.
- [ ] Each runnable via `ruby -Ilib examples/basic.rb` (they hit the live API; say so in a
      comment; keep them out of the gem `files` glob? No — they're excluded already since
      the glob only ships `lib/`).

### CHANGELOG.md

- [ ] Keep-a-Changelog format, single `## [0.1.0] - <date>` section listing the feature set.

### Final QA

- [ ] `bundle exec rake` green; `rubocop` zero offenses (no new disables without a comment).
- [ ] SimpleCov line coverage ≥ 95% on `lib/` (it should be near 100% naturally; don't
      chase the last % with junk tests — if below, look for genuinely untested branches,
      e.g. error paths).
- [ ] `gem build tcgdex.gemspec` clean, `gem install ./tcgdex-0.1.0.gem` into a temp
      gemset/dir works, `ruby -e 'require "tcgdex"'` from that install works.
- [ ] `LIVE=1` smoke green (final end-to-end proof: name == "Furret").
- [ ] Read the diff of the whole repo once (`git log --oneline`, `git diff --stat
      $(git rev-list --max-parents=0 HEAD)..HEAD`) for stray debug code/TODOs.
- [ ] Mark milestone 7 done in `00-overview.md`; final commit:
      `docs: add README, examples, changelog; finish 0.1.0`.

## Acceptance criteria

A newcomer can: clone, `bundle install`, `bundle exec rake` (green, offline), read the
README, run `examples/basic.rb`, and get Furret's attacks printed — without reading
`docs/plan/`.

## Out of scope

Publishing to RubyGems; release automation; GraphQL API support; typed pricing models;
retry/backoff logic. (All possible future work — list them in README "Roadmap" only if
you feel like it.)

## Handoff notes

(fill in only if stopping mid-milestone)
