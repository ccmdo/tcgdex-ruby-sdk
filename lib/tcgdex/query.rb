# frozen_string_literal: true

require "uri"

class TCGdex
  # Chainable builder for the API's filtering, sorting and pagination params.
  #
  # Every filter method takes a field name (Symbol or String — any JSON key of the
  # full object) and returns `self`, so calls chain. Duplicate keys are legal and
  # keep their order, which is how you express a range:
  #
  #   TCGdex::Query.new.gte(:hp, 50).lte(:hp, 90)
  #   # => hp=gte:50&hp=lte:90
  #
  # @example The whole surface at once
  #   query = TCGdex::Query.new
  #     .contains(:name, "pika")          # laxist, case-insensitive: "pika" anywhere
  #     .gte(:hp, 60)
  #     .sort(:hp, :desc)
  #     .paginate(page: 1, items_per_page: 20)
  #   tcgdex.card.list(query)
  class Query
    # @return [Array<String>] the sort orders the API accepts
    ORDERS = %w[ASC DESC].freeze

    def initialize
      @params = []
    end

    # Laxist (partial, case-insensitive) match. Wildcards pass through: `"*chu"`
    # anchors to the end, `"fu*"` to the start.
    #
    # @example
    #   query.contains(:name, "pika")   # name=pika
    # @param key [Symbol, String]
    # @param value [Object]
    # @return [self]
    def contains(key, value)
      add(key, value)
    end
    alias like contains
    alias includes contains

    # Laxist negation: everything {#contains} would *not* match.
    #
    # @example
    #   query.not_contains(:name, "pika")   # name=not:pika
    # @return [self]
    def not_contains(key, value)
      add(key, "not:#{value}")
    end
    alias not_like not_contains

    # Strict equality. Pipe-separate the value to OR several of them:
    # `equal(:name, "Furret|Pikachu")`.
    #
    # @example
    #   query.equal(:name, "Furret")   # name=eq:Furret
    # @return [self]
    def equal(key, value)
      add(key, "eq:#{value}")
    end
    alias eq equal

    # Strict negation.
    #
    # @example
    #   query.not_equal(:name, "Furret")   # name=neq:Furret
    # @return [self]
    def not_equal(key, value)
      add(key, "neq:#{value}")
    end
    alias neq not_equal

    # @example
    #   query.greater_than(:hp, 50)   # hp=gt:50
    # @return [self]
    def greater_than(key, value)
      add(key, "gt:#{value}")
    end
    alias gt greater_than

    # @example
    #   query.greater_or_equal(:hp, 50)   # hp=gte:50
    # @return [self]
    def greater_or_equal(key, value)
      add(key, "gte:#{value}")
    end
    alias gte greater_or_equal

    # @example
    #   query.less_than(:hp, 50)   # hp=lt:50
    # @return [self]
    def less_than(key, value)
      add(key, "lt:#{value}")
    end
    alias lt less_than

    # @example
    #   query.less_or_equal(:hp, 50)   # hp=lte:50
    # @return [self]
    def less_or_equal(key, value)
      add(key, "lte:#{value}")
    end
    alias lte less_or_equal

    # Matches records where the field is absent or null.
    #
    # @example
    #   query.null(:effect)   # effect=null:
    # @return [self]
    def null(key)
      add(key, "null:")
    end

    # Matches records where the field has a value.
    #
    # @example
    #   query.not_null(:effect)   # effect=notnull:
    # @return [self]
    def not_null(key)
      add(key, "notnull:")
    end

    # Sorts the result set. The API defaults to `releaseDate`, then `localId`, then `id`.
    #
    # @example
    #   query.sort(:hp, :desc)   # sort:field=hp&sort:order=DESC
    # @param key [Symbol, String] field to sort on
    # @param order [Symbol, String] `:asc` or `:desc` (case-insensitive)
    # @raise [ArgumentError] on any other order
    # @return [self]
    def sort(key, order = :asc)
      add("sort:field", key.to_s)
      add("sort:order", normalize_order(order))
    end

    # Pages the result set. The API returns everything unless pagination is asked for.
    #
    # @example
    #   query.paginate(page: 1, items_per_page: 20)
    #   # pagination:page=1&pagination:itemsPerPage=20
    # @param page [Integer] 1-based
    # @param items_per_page [Integer]
    # @return [self]
    def paginate(page:, items_per_page: 100)
      add("pagination:page", page)
      add("pagination:itemsPerPage", items_per_page)
    end

    # @return [Array<Array(String, Object)>] the unencoded key/value pairs, in order
    def to_params
      @params.map(&:dup)
    end

    # @return [String] the encoded query string, with no leading "?"
    def to_s
      URI.encode_www_form(@params)
    end

    private

    def add(key, value)
      @params << [key.to_s, value]
      self
    end

    def normalize_order(order)
      normalized = order.to_s.upcase
      return normalized if ORDERS.include?(normalized)

      raise ArgumentError, "sort order must be one of :asc, :desc (got #{order.inspect})"
    end
  end
end
