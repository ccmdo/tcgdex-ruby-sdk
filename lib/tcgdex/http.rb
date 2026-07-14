# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"
require "uri"

require_relative "version"
require_relative "errors"
require_relative "cache"

class TCGdex
  # The single transport path for the SDK: every request goes through here.
  #
  # The TCGdex API is free and unauthenticated, so responses are cached by
  # default (1 hour) — that is our half of the bargain.
  class Http
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 30
    USER_AGENT = "tcgdex-ruby-sdk/#{TCGdex::VERSION}".freeze

    # Transport-level failures, all reported as {TCGdex::NetworkError}.
    TRANSPORT_ERRORS = [
      SocketError,
      Timeout::Error, # covers Net::OpenTimeout and Net::ReadTimeout
      Errno::ECONNREFUSED,
      Errno::ECONNRESET,
      OpenSSL::SSL::SSLError,
      EOFError
    ].freeze

    # @return [#get, #set, nil] the cache; nil disables caching entirely
    attr_accessor :cache

    # @return [Numeric] seconds a cached response stays fresh
    attr_accessor :cache_ttl

    # @param cache [#get, #set, nil]
    # @param cache_ttl [Numeric]
    def initialize(cache: Cache.new, cache_ttl: 3600)
      @cache = cache
      @cache_ttl = cache_ttl
    end

    # GETs a URL and parses the JSON response.
    #
    # A missing resource (404) yields nil and is not cached — it is a normal outcome
    # (bad id, or content not translated into the requested language).
    #
    # @param url [String] the full request URL
    # @return [Hash, Array, String, Numeric, nil] the parsed body, or nil when the
    #   resource does not exist (404) or is otherwise a non-2xx, non-5xx response
    # @raise [TCGdex::ServerError] on a 5xx response
    # @raise [TCGdex::NetworkError] when the request could not be completed
    # @raise [TCGdex::Error] when a 2xx body is not valid JSON
    def get(url)
      cached = cache&.get(url)
      return cached unless cached.nil?

      body = get_raw(url)
      return nil if body.nil?

      parse(body).tap { |value| cache&.set(url, value, cache_ttl) }
    end

    # GETs a URL and returns the response body unparsed — for binaries (card images).
    #
    # Never cached: image bodies are large and the cache is unbounded.
    #
    # @param url [String] the full request URL
    # @return [String, nil] the raw body, or nil when the resource does not exist
    # @raise [TCGdex::ServerError] on a 5xx response
    # @raise [TCGdex::NetworkError] when the request could not be completed
    def get_raw(url)
      response = perform(URI.parse(url))

      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPServerError
        raise ServerError.new("TCGdex API server error (#{response.code})",
                              status: response.code.to_i, body: response.body)
      end
    end

    private

    def perform(uri)
      Net::HTTP.start(uri.host, uri.port,
                      use_ssl: uri.scheme == "https",
                      open_timeout: OPEN_TIMEOUT,
                      read_timeout: READ_TIMEOUT) do |http|
        http.get(uri.request_uri, "User-Agent" => USER_AGENT)
      end
    rescue *TRANSPORT_ERRORS => e
      # `raise` inside a rescue keeps the original exception as #cause.
      raise NetworkError, "TCGdex API request failed: #{e.class}: #{e.message}"
    end

    def parse(body)
      JSON.parse(body)
    rescue JSON::ParserError => e
      raise Error, "TCGdex API returned malformed JSON: #{e.message}"
    end
  end
end
