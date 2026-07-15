# frozen_string_literal: true

class TCGdex
  # A generic resource endpoint: `#get(id)` for one item, `#list(query)` for many.
  #
  # One instance is wired per resource (`cards`, `sets`, `rarities`, …). It reads the
  # language and base URL from the client at request time, so changing
  # {TCGdex#language} or {TCGdex#endpoint_url} takes effect immediately.
  class Endpoint
    # @param client [TCGdex]
    # @param item_class [Class] model for `GET /{path}/{id}` (Card, Set, Serie, StringEndpoint)
    # @param brief_class [Class, nil] model for `GET /{path}` list items; nil means the list
    #   is raw values (the String/Integer indexes like `types` and `hp`)
    # @param path [String] the URL segment, e.g. "cards" or "dex-ids"
    def initialize(client, item_class, brief_class, path)
      @client = client
      @item_class = item_class
      @brief_class = brief_class
      @path = path
    end

    # Fetches one full item by id. Spaces in the id are fine — the transport escapes
    # them (and only them, so pre-encoded ids like Unown's "exu-%3F" pass through).
    #
    # @param id [String, Integer] the resource id (or an index value, e.g. a rarity name)
    # @return [BaseModel, nil] the full model, or nil when it does not exist
    def get(id)
      data = @client.fetch(@path, id)
      @item_class.new(data, client: @client) unless data.nil?
    end

    # Lists the resource, optionally filtered/sorted/paginated.
    #
    # @param query [TCGdex::Query, nil]
    # @return [Array<BaseModel>, Array] brief models, or raw values for the String/Integer
    #   indexes
    def list(query = nil)
      data = @client.fetch(@path, query: query)
      return [] if data.nil?
      return data if @brief_class.nil?

      data.map { |element| @brief_class.new(element, client: @client) }
    end
  end
end
