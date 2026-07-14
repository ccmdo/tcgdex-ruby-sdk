# frozen_string_literal: true

require_relative "base"
require_relative "subs"

class TCGdex
  # The resume of a set, as returned by list endpoints and embedded in cards.
  class SetBrief < BaseModel
    attribute :id
    attribute :name
    attribute :logo
    attribute :symbol
    attribute :card_count, model: CardCountBrief

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

    # @return [TCGdex::Set, nil] the full set, fetched by id
    # @raise [TCGdex::Error] when the model has no client attached
    def full_set
      client!.set.get(id)
    end
  end
end
