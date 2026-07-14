# frozen_string_literal: true

require_relative "tcgdex/version"
require_relative "tcgdex/errors"
require_relative "tcgdex/cache"
require_relative "tcgdex/http"
require_relative "tcgdex/query"
require_relative "tcgdex/endpoint"

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

# Client for the TCGdex Pokémon TCG API (https://tcgdex.dev).
#
# The class is also the namespace for everything else — {TCGdex::Query},
# {TCGdex::Card}, and so on.
#
# @example
#   tcgdex = TCGdex.new("en")
#   card = tcgdex.card.get("swsh3-136")
#   card.name                            # => "Furret"
#   cards = tcgdex.card.list(TCGdex::Query.new.contains(:name, "pika"))
#   tcgdex.type.list                     # => ["Colorless", "Darkness", ...]
#   tcgdex.random.card                   # => a random TCGdex::Card
class TCGdex
  DEFAULT_ENDPOINT_URL = "https://api.tcgdex.net/v2"
  DEFAULT_LANGUAGE = "en"

  # Resource endpoints, as `reader => [item_class, brief_class, path]`. A nil brief
  # class means the list returns raw values (the String/Integer indexes).
  ENDPOINTS = {
    card: [Card, CardBrief, "cards"],
    set: [Set, SetBrief, "sets"],
    serie: [Serie, SerieBrief, "series"],
    category: [StringEndpoint, nil, "categories"],
    dex_id: [StringEndpoint, nil, "dex-ids"],
    energy_type: [StringEndpoint, nil, "energy-types"],
    hp: [StringEndpoint, nil, "hp"],
    illustrator: [StringEndpoint, nil, "illustrators"],
    rarity: [StringEndpoint, nil, "rarities"],
    regulation_mark: [StringEndpoint, nil, "regulation-marks"],
    retreat: [StringEndpoint, nil, "retreats"],
    stage: [StringEndpoint, nil, "stages"],
    suffix: [StringEndpoint, nil, "suffixes"],
    trainer_type: [StringEndpoint, nil, "trainer-types"],
    type: [StringEndpoint, nil, "types"],
    variant: [StringEndpoint, nil, "variants"]
  }.freeze

  # @return [String] the API language code, e.g. "en", "fr", "ja"
  attr_accessor :language

  # @return [String] the base URL, without a trailing slash
  attr_accessor :endpoint_url

  # @return [TCGdex::Http] the shared transport, exposed for `get_raw` and model helpers
  attr_reader :http

  # @param language [String, Symbol] API language code (default "en")
  # @param endpoint_url [String] override the API base URL
  # @param cache [#get, #set, nil] a cache; nil disables caching
  # @param cache_ttl [Numeric] seconds a cached response stays fresh
  def initialize(language = DEFAULT_LANGUAGE, endpoint_url: DEFAULT_ENDPOINT_URL,
                 cache: Cache.new, cache_ttl: 3600)
    @language = language.to_s
    @endpoint_url = endpoint_url
    @http = Http.new(cache: cache, cache_ttl: cache_ttl)
    @endpoints = {}
  end

  ENDPOINTS.each_key do |name|
    define_method(name) do
      @endpoints[name] ||= Endpoint.new(self, *ENDPOINTS[name])
    end
  end

  # @return [Random] the random-resource endpoints (`random.card`, `.set`, `.serie`)
  def random
    @random ||= Random.new(self)
  end

  # @return [Numeric] seconds a cached response stays fresh
  def cache_ttl
    http.cache_ttl
  end

  # @param ttl [Numeric]
  def cache_ttl=(ttl)
    http.cache_ttl = ttl
  end

  # @return [#get, #set, nil] the cache; nil when caching is disabled
  def cache
    http.cache
  end

  # @param cache [#get, #set, nil] a cache duck type, or nil to disable caching
  def cache=(cache)
    http.cache = cache
  end

  # Low-level escape hatch: GET an arbitrary path under the current language and return
  # the parsed JSON. Use it to reach endpoints this SDK does not model yet.
  #
  # @example
  #   tcgdex.fetch("sets", "swsh3", "136")   # => parsed Hash for /en/sets/swsh3/136
  # @param path_segments [Array<String>] joined with "/" after the language
  # @param query [TCGdex::Query, nil] appended as a query string when present
  # @return [Hash, Array, nil] the parsed body, or nil on a 404
  def fetch(*path_segments, query: nil)
    url = "#{endpoint_url}/#{language}/#{path_segments.join("/")}"
    query_string = query&.to_s
    url = "#{url}?#{query_string}" unless query_string.nil? || query_string.empty?
    http.get(url)
  end

  # The `random/*` endpoints, reached through {TCGdex#random}.
  class Random
    # @param client [TCGdex]
    def initialize(client)
      @client = client
    end

    # @return [TCGdex::Card, nil] a random card
    def card
      wrap(Card, "card")
    end

    # @return [TCGdex::Set, nil] a random set
    def set
      wrap(Set, "set")
    end

    # @return [TCGdex::Serie, nil] a random serie
    def serie
      wrap(Serie, "serie")
    end

    private

    def wrap(model, resource)
      data = @client.fetch("random", resource)
      model.new(data, client: @client) unless data.nil?
    end
  end
end
