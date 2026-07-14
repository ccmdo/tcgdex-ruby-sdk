# frozen_string_literal: true

require_relative "base"
require_relative "subs"
require_relative "set_brief"

class TCGdex
  # A full card, as returned by `/cards/{id}` and `/sets/{setId}/{localId}`.
  class Card < BaseModel
    attribute :id
    attribute :local_id
    attribute :name
    attribute :image
    attribute :category
    attribute :illustrator
    attribute :rarity
    attribute :variants, model: CardVariants
    # Live-only, and snake_case in the JSON. Left as raw Hashes: the pricing inside
    # has hyphenated keys ("avg-holo", "reverse-holofoil") not worth modelling yet.
    attribute :variants_detailed, key: "variants_detailed"
    attribute :set, model: SetBrief
    attribute :dex_id
    attribute :hp
    attribute :types
    attribute :evolve_from
    attribute :description
    attribute :level
    attribute :stage
    attribute :suffix
    attribute :item, model: CardItem
    attribute :abilities, model: CardAbility, array: true
    attribute :attacks, model: CardAttack, array: true
    attribute :weaknesses, model: WeakRes, array: true
    attribute :resistances, model: WeakRes, array: true
    attribute :retreat
    attribute :effect
    attribute :trainer_type
    attribute :energy_type
    attribute :regulation_mark
    attribute :legal, model: Legal
    # nil means "in every booster of the set"; [] means "in none of them".
    attribute :boosters, model: Booster, array: true
    attribute :updated
    attribute :pricing

    # The API returns image bases without an extension; pick the rendering here.
    #
    # @example
    #   card.image_url(quality: :low, extension: :webp)
    #   # => "https://assets.tcgdex.net/en/swsh/swsh3/136/low.webp"
    # @param quality [Symbol, String] :high or :low
    # @param extension [Symbol, String] :png, :jpg or :webp (png and webp are transparent)
    # @raise [ArgumentError] on an unknown quality or extension
    # @return [String, nil] nil when the card has no image
    def image_url(quality: :high, extension: :png)
      image_asset_url(image, quality, extension)
    end

    # Downloads the image. Not cached.
    #
    # @return [String, nil] the binary image, or nil when the card has no image
    # @raise [TCGdex::Error] when the model has no client attached
    def image_data(quality: :high, extension: :png)
      url = image_url(quality: quality, extension: extension)
      client!.http.get_raw(url) unless url.nil?
    end

    # @return [TCGdex::Set, nil] the full parent set, fetched by id
    # @raise [TCGdex::Error] when the model has no client attached
    def full_set
      client!.set.get(set.id) unless set.nil?
    end
  end
end
