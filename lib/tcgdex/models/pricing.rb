# frozen_string_literal: true

require_relative "base"

class TCGdex
  # TCGplayer prices for one printing of a card. Prices are Floats in
  # {PricingTcgplayer#unit}; absent metrics read as nil.
  class PricingTcgplayerVariant < BaseModel
    attribute :product_id
    attribute :low_price
    attribute :mid_price
    attribute :high_price
    attribute :market_price
    attribute :direct_low_price
  end

  # TCGplayer market prices, one slot per printing; slots the card was never
  # printed in read as nil. `unit` is the currency code (e.g. "USD").
  class PricingTcgplayer < BaseModel
    attribute :updated
    attribute :unit
    attribute :normal, model: PricingTcgplayerVariant
    attribute :holofoil, model: PricingTcgplayerVariant
    # The remaining printings have hyphenated (and digit-led) JSON keys.
    attribute :reverse_holofoil, key: "reverse-holofoil", model: PricingTcgplayerVariant
    attribute :first_edition, key: "1st-edition", model: PricingTcgplayerVariant
    attribute :first_edition_holofoil, key: "1st-edition-holofoil", model: PricingTcgplayerVariant
    attribute :unlimited, model: PricingTcgplayerVariant
    attribute :unlimited_holofoil, key: "unlimited-holofoil", model: PricingTcgplayerVariant
  end

  # Cardmarket market prices. `unit` is the currency code (e.g. "EUR"); the
  # `*_holo` twins price the foil printing, and their JSON keys are hyphenated.
  class PricingCardmarket < BaseModel
    attribute :updated
    attribute :unit
    attribute :id_product
    attribute :avg
    attribute :low
    attribute :trend
    attribute :avg1
    attribute :avg7
    attribute :avg30
    attribute :avg_holo, key: "avg-holo"
    attribute :low_holo, key: "low-holo"
    attribute :trend_holo, key: "trend-holo"
    attribute :avg1_holo, key: "avg1-holo"
    attribute :avg7_holo, key: "avg7-holo"
    attribute :avg30_holo, key: "avg30-holo"
  end

  # Market pricing for a card, per marketplace. Live-only: present on the API
  # but not in the official Python/JavaScript SDKs.
  class Pricing < BaseModel
    attribute :cardmarket, model: PricingCardmarket
    attribute :tcgplayer, model: PricingTcgplayer
  end

  # One concrete printing of a card (normal, reverse, jumbo…) with its own
  # pricing. `sub_type`, `stamp` and `foil` only appear on special printings.
  class VariantDetailed < BaseModel
    attribute :type
    attribute :size
    attribute :variant_id
    attribute :sub_type
    attribute :stamp
    attribute :foil
    attribute :pricing, model: Pricing
  end
end
