# frozen_string_literal: true

# Entry point and client for the TCGdex Pokémon TCG API.
#
# The class body is defined in the files required below; it gains its
# configuration and endpoints in later milestones.
require_relative "tcgdex/version"
require_relative "tcgdex/errors"
require_relative "tcgdex/cache"
require_relative "tcgdex/http"
require_relative "tcgdex/query"
