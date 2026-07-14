# frozen_string_literal: true

require_relative "base"
require_relative "card_brief"

class TCGdex
  # One value of a card-attribute index (a rarity, an illustrator, a type…) together
  # with the cards carrying it, as returned by `/{endpoint}/{value}`.
  #
  # The API echoes the value back lowercased, so `#name` may not match what you asked
  # for. Some indexes (`types`, `hp`) currently return an empty `cards` list.
  class StringEndpoint < BaseModel
    attribute :name
    attribute :cards, model: CardBrief, array: true
  end
end
