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
    # @return [Integer] seconds to wait for the connection to open
    OPEN_TIMEOUT = 10
    # @return [Integer] seconds to wait for the response body
    READ_TIMEOUT = 30
    # @return [String] the `User-Agent` header sent on every request
    USER_AGENT = "tcgdex-ruby-sdk/#{TCGdex::VERSION}".freeze
    # @return [Integer] redirect hops followed before giving up
    MAX_REDIRECTS = 5

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
    # The cache stores the raw JSON body and every call re-parses it, so each caller
    # gets an object it alone owns — mutating a result can never corrupt what later
    # calls see. (It also means pluggable caches only ever store Strings, which
    # serialize anywhere.)
    #
    # @param url [String] the full request URL
    # @return [Hash, Array, String, Numeric, nil] the parsed body, or nil when the
    #   resource does not exist (404) or is otherwise a non-2xx, non-5xx response
    # @raise [TCGdex::ServerError] on a 5xx response
    # @raise [TCGdex::NetworkError] when the request could not be completed
    # @raise [TCGdex::Error] when a 2xx body is not valid JSON
    def get(url)
      cached = cache&.get(url)
      return parse(cached) unless cached.nil?

      body = get_raw(url)
      return nil if body.nil?

      value = parse(body)
      cache&.set(url, body, cache_ttl)
      value
    end

    # GETs a URL and returns the response body unparsed — for binaries (card images).
    #
    # Never cached: image bodies are large and the cache is unbounded.
    #
    # Redirects are followed (at most {MAX_REDIRECTS} hops) — assets can move without
    # images silently "disappearing".
    #
    # @param url [String] the full request URL
    # @return [String, nil] the raw body, or nil when the resource does not exist
    # @raise [TCGdex::ServerError] on a 5xx response
    # @raise [TCGdex::NetworkError] when the request could not be completed,
    #   including a redirect chain longer than {MAX_REDIRECTS}
    def get_raw(url)
      response = perform_following_redirects(parse_uri(url))

      case response
      when Net::HTTPSuccess
        response.body
      when Net::HTTPServerError
        raise ServerError.new("TCGdex API server error (#{response.code})",
                              status: response.code.to_i, body: response.body)
      end
    end

    private

    # Escape spaces only, matching the id-escaping rule: it makes the low-level `fetch`
    # escape hatch tolerant of unescaped values (e.g. "tetsuya koizumi") without
    # re-encoding already-percent-encoded data. Idempotent for URLs already escaped.
    def parse_uri(url)
      URI.parse(url.to_s.gsub(" ", "%20"))
    rescue URI::InvalidURIError => e
      raise Error, "TCGdex API request URL is invalid: #{e.message}"
    end

    # A 3xx without a Location falls through untouched (e.g. 304), landing on the
    # same nil as other non-2xx, non-5xx responses.
    def perform_following_redirects(uri)
      response = perform(uri)
      hops = 0

      while response.is_a?(Net::HTTPRedirection) && (location = response["Location"])
        hops += 1
        raise NetworkError, "TCGdex API redirected more than #{MAX_REDIRECTS} times" if hops > MAX_REDIRECTS

        uri = redirect_target(uri, location)
        response = perform(uri)
      end

      response
    end

    # Location may be relative (RFC 7231 §7.1.2); resolve it against the current URI.
    def redirect_target(uri, location)
      uri + location
    rescue URI::InvalidURIError, URI::BadURIError => e
      raise Error, "TCGdex API redirect location is invalid: #{e.message}"
    end

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
