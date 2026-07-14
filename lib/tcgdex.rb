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

# Models: base and sub-structs first, then the resumes the full models embed.
require_relative "tcgdex/models/base"
require_relative "tcgdex/models/subs"
require_relative "tcgdex/models/card_brief"
require_relative "tcgdex/models/set_brief"
require_relative "tcgdex/models/serie_brief"
require_relative "tcgdex/models/card"
require_relative "tcgdex/models/set"
require_relative "tcgdex/models/serie"
require_relative "tcgdex/models/string_endpoint"
