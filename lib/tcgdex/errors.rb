# frozen_string_literal: true

class TCGdex
  # Base class for every error raised by this SDK. Rescue this to catch them all.
  #
  # Also raised directly when the API returns a 2xx response whose body is not
  # valid JSON.
  class Error < StandardError; end

  # Raised when the TCGdex API responds with a 5xx status.
  #
  # A missing or untranslated resource is *not* an error — those come back as
  # `nil` (see {TCGdex::Http#get}).
  #
  # @!attribute [r] status
  #   @return [Integer, nil] the HTTP status code (e.g. 503)
  # @!attribute [r] body
  #   @return [String, nil] the raw, unparsed response body
  class ServerError < Error
    attr_reader :status, :body

    # @param message [String]
    # @param status [Integer, nil]
    # @param body [String, nil]
    def initialize(message = "TCGdex API server error", status: nil, body: nil)
      @status = status
      @body = body
      super(message)
    end
  end

  # Raised when the request never completed: DNS failure, refused/reset connection,
  # TLS failure or timeout. The underlying exception is preserved as `#cause`.
  class NetworkError < Error; end
end
