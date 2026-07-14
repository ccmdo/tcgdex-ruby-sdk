# Milestone 01 — Gem scaffold & tooling

## Objective

A buildable, testable, lintable empty gem: `bundle exec rake` runs RSpec + RuboCop green,
`gem build tcgdex.gemspec` produces a .gem. No SDK logic yet beyond the version constant.

## Prerequisites

None (first milestone). Read `00-overview.md` for conventions.

## Tasks

- [ ] `tcgdex.gemspec` — see sketch below. Zero runtime dependencies.
- [ ] `Gemfile` — `source "https://rubygems.org"; gemspec` plus dev group if preferred
      (dev deps can live in the gemspec `add_development_dependency` or the Gemfile —
      pick the Gemfile for a personal project so the gemspec stays minimal).
      Dev deps: `rake`, `rspec` (~> 3.13), `webmock` (~> 3.23), `vcr` (~> 6.2),
      `rubocop` (~> 1.65), `rubocop-rspec`, `rubocop-rake`, `yard`, `simplecov`.
- [ ] `Rakefile` — `RSpec::Core::RakeTask` + `RuboCop::RakeTask`; `task default: %i[spec rubocop]`.
- [ ] `lib/tcgdex/version.rb` — `TCGdex::VERSION = "0.1.0"` (define `class TCGdex` here so
      the constant type is consistent everywhere: `class TCGdex; VERSION = "0.1.0"; end`).
- [ ] `lib/tcgdex.rb` — for now just `require_relative "tcgdex/version"` and the
      `class TCGdex; end` shell; grows in later milestones.
- [ ] `.rspec` — `--require spec_helper --format documentation`.
- [ ] `spec/spec_helper.rb` — standard RSpec config; SimpleCov started at the top (before
      requires); WebMock `disable_net_connect!(allow_localhost: false)`; leave VCR config
      for milestone 06.
- [ ] `spec/tcgdex_spec.rb` — trivial spec asserting `TCGdex::VERSION` matches semver.
- [ ] `.rubocop.yml` — see sketch. Keep it low-friction.
- [ ] `bin/console` — IRB with the gem loaded (`chmod +x`).
- [ ] `.gitignore` — `*.gem`, `/coverage/`, `/.yardoc/`, `/doc/` (but NOT `docs/`), `Gemfile.lock`
      (library convention).
- [ ] Optional (do last, don't fight it if the runner isn't available):
      `.github/workflows/ci.yml` running `bundle exec rake` on ruby 3.2/3.3/3.4.
      **No release/publish workflow** — explicitly out of scope for this project.
- [ ] Commit: `feat: scaffold tcgdex gem skeleton and tooling`.

## Sketches

`tcgdex.gemspec`:

```ruby
# frozen_string_literal: true

require_relative "lib/tcgdex/version"

Gem::Specification.new do |spec|
  spec.name     = "tcgdex"
  spec.version  = TCGdex::VERSION
  spec.authors  = ["Steven H"]
  spec.summary  = "Ruby SDK for the TCGdex Pokémon TCG API"
  spec.description = "Query Pokémon Trading Card Game cards, sets and series from " \
                     "the multilingual TCGdex API (https://tcgdex.dev)."
  spec.homepage = "https://github.com/<owner>/tcgdex-ruby-sdk" # placeholder ok, no publish planned
  spec.license  = "MIT"
  spec.required_ruby_version = ">= 3.2"
  spec.files    = Dir["lib/**/*.rb", "LICENSE*", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]
  spec.metadata["rubygems_mfa_required"] = "true"
end
```

`.rubocop.yml` starting point (tune, don't expand):

```yaml
plugins:
  - rubocop-rspec
  - rubocop-rake

AllCops:
  TargetRubyVersion: 3.2
  NewCops: enable
  Exclude:
    - "bin/**/*"
    - "vendor/**/*"

Style/Documentation:
  Enabled: false      # YARD covers docs (milestone 07)
Metrics/BlockLength:
  Exclude: ["spec/**/*", "*.gemspec"]
Layout/LineLength:
  Max: 110
RSpec/ExampleLength:
  Max: 15
RSpec/MultipleExpectations:
  Max: 5
```

Note: rubocop >= 1.72 uses `plugins:`; if an older rubocop resolves, use `require:` instead.
Add MIT `LICENSE` file (standard text, copyright Steven H).

## Acceptance criteria

```bash
bundle install
bundle exec rake          # RSpec: 1 example 0 failures; RuboCop: no offenses
gem build tcgdex.gemspec  # produces tcgdex-0.1.0.gem (delete it after; it's gitignored)
ruby -Ilib -e 'require "tcgdex"; puts TCGdex::VERSION'   # => 0.1.0
```

## Out of scope

Any HTTP/model/query code; release automation; CODE_OF_CONDUCT/CONTRIBUTING.

## Handoff notes

(fill in only if stopping mid-milestone)
