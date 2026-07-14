# frozen_string_literal: true

require_relative "lib/tcgdex/version"

Gem::Specification.new do |spec|
  spec.name        = "tcgdex"
  spec.version     = TCGdex::VERSION
  spec.authors     = ["Steven H"]
  spec.summary     = "Ruby SDK for the TCGdex Pokémon TCG API"
  spec.description = "Query Pokémon Trading Card Game cards, sets and series from " \
                     "the multilingual TCGdex API (https://tcgdex.dev)."
  spec.homepage    = "https://github.com/ccmdo/tcgdex-ruby-sdk"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir["lib/**/*.rb", "LICENSE*", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"
end
