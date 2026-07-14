# frozen_string_literal: true

require_relative "base"
require_relative "subs"
require_relative "card"
require_relative "card_brief"
require_relative "serie_brief"

class TCGdex
  # A full set, as returned by `/sets/{id}`.
  class Set < BaseModel
    attribute :id
    attribute :name
    attribute :logo
    attribute :symbol
    attribute :card_count, model: CardCount
    # The URL path is "series", but the key on a set is singular.
    attribute :serie, model: SerieBrief
    attribute :tcg_online
    attribute :release_date
    attribute :legal, model: Legal
    attribute :cards, model: CardBrief, array: true
    attribute :boosters, model: Booster, array: true
    attribute :abbreviation, model: Abbreviation

    # @param extension [Symbol, String] :png, :jpg or :webp
    # @raise [ArgumentError] on an unknown extension
    # @return [String, nil] nil when the set has no logo
    def logo_url(extension = :png)
      asset_url(logo, extension)
    end

    # @param extension [Symbol, String] :png, :jpg or :webp
    # @raise [ArgumentError] on an unknown extension
    # @return [String, nil] nil when the set has no symbol
    def symbol_url(extension = :png)
      asset_url(symbol, extension)
    end

    # Fetches one full card by its position in this set, via `/sets/{id}/{localId}` —
    # the id printed on the card, which is all you have when holding one.
    #
    # @example
    #   set.card("136")   # => #<TCGdex::Card "swsh3-136">
    # @param local_id [String, Integer]
    # @return [TCGdex::Card, nil] nil when the set has no such card
    # @raise [TCGdex::Error] when the model has no client attached
    def card(local_id)
      data = client!.fetch("sets", id, local_id.to_s)
      Card.new(data, client: client) unless data.nil?
    end
  end
end
