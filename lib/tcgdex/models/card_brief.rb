# frozen_string_literal: true

require_relative "base"

class TCGdex
  # The resume of a card, as returned by list endpoints. {#full_card} fetches the rest.
  class CardBrief < BaseModel
    attribute :id
    attribute :local_id
    attribute :name
    attribute :image

    # The API returns image bases without an extension; pick the rendering here.
    #
    # @example
    #   card.image_url(quality: :high, extension: :png)
    #   # => "https://assets.tcgdex.net/en/swsh/swsh3/136/high.png"
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

    # @return [TCGdex::Card, nil] the full card, fetched by id
    # @raise [TCGdex::Error] when the model has no client attached
    def full_card
      client!.card.get(id)
    end
  end
end
