# frozen_string_literal: true

require_relative "base"
require_relative "set_brief"

class TCGdex
  # A full serie, as returned by `/series/{id}`.
  class Serie < BaseModel
    attribute :id
    attribute :name
    attribute :logo
    attribute :sets, model: SetBrief, array: true
    attribute :first_set, model: SetBrief
    attribute :last_set, model: SetBrief
    attribute :release_date

    # @param extension [Symbol, String] :png, :jpg or :webp
    # @raise [ArgumentError] on an unknown extension
    # @return [String, nil] nil when the serie has no logo
    def logo_url(extension = :png)
      asset_url(logo, extension)
    end
  end
end
