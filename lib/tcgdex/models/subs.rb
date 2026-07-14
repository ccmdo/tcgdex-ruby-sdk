# frozen_string_literal: true

require_relative "base"

class TCGdex
  # Which printings of a card exist.
  class CardVariants < BaseModel
    attribute :normal
    attribute :reverse
    attribute :holo
    attribute :first_edition
    attribute :w_promo
  end

  # An attack: its energy cost, effect and damage.
  class CardAttack < BaseModel
    attribute :name
    attribute :cost
    attribute :effect
    # Usually an Integer, sometimes a String multiplier ("x20", "20+").
    attribute :damage
  end

  # A Pokémon ability (Poké-Power, Poké-Body, Ability…).
  class CardAbility < BaseModel
    attribute :type
    attribute :name
    attribute :effect
  end

  # The item a Pokémon card holds.
  class CardItem < BaseModel
    attribute :name
    attribute :effect
  end

  # A weakness or a resistance: a type and its modifier (e.g. "×2", "-30").
  class WeakRes < BaseModel
    attribute :type
    attribute :value
  end

  # Tournament legality.
  class Legal < BaseModel
    attribute :standard
    attribute :expanded
  end

  # Card totals for a set. `total` counts secret/alternate cards; `official` is the
  # number printed on the cards themselves.
  class CardCount < BaseModel
    attribute :total
    attribute :official
    attribute :normal
    attribute :reverse
    attribute :holo
    attribute :first_ed
  end

  # The card totals carried by a set resume.
  class CardCountBrief < BaseModel
    attribute :total
    attribute :official
  end

  # A booster pack a card can be pulled from.
  class Booster < BaseModel
    attribute :id
    attribute :name
    attribute :logo
    # Already snake_case in the API's JSON, unlike every other multi-word key.
    attribute :artwork_front, key: "artwork_front"
    attribute :artwork_back, key: "artwork_back"
  end

  # A set's short code (e.g. "DAA" for Darkness Ablaze).
  class Abbreviation < BaseModel
    attribute :official
    attribute :localized
  end
end
