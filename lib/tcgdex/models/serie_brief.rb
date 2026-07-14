# frozen_string_literal: true

require_relative "base"

class TCGdex
  # The resume of a serie, as returned by list endpoints and embedded in sets.
  class SerieBrief < BaseModel
    attribute :id
    attribute :name
    attribute :logo

    # @param extension [Symbol, String] :png, :jpg or :webp
    # @raise [ArgumentError] on an unknown extension
    # @return [String, nil] nil when the serie has no logo (some genuinely don't)
    def logo_url(extension = :png)
      asset_url(logo, extension)
    end

    # @return [TCGdex::Serie, nil] the full serie, fetched by id
    # @raise [TCGdex::Error] when the model has no client attached
    def full_serie
      client!.serie.get(id)
    end
  end
end
