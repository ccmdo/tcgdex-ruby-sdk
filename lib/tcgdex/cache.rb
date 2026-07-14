# frozen_string_literal: true

class TCGdex
  # Thread-safe in-memory cache with per-entry TTL, keyed by request URL.
  #
  # This is the default cache for {TCGdex::Http}. It is a duck type: any object
  # responding to `#get(key)` and `#set(key, value, ttl)` can replace it.
  #
  # Deliberately dumb — there is no max size and no LRU eviction, so a very
  # long-lived process querying many distinct URLs will grow this store
  # unboundedly. Call {#clear} periodically, or plug in your own cache.
  class Cache
    def initialize
      @store = {}
      @mutex = Mutex.new
    end

    # @param key [String]
    # @return [Object, nil] the cached value, or nil if absent or expired
    #   (expired entries are dropped on read)
    def get(key)
      @mutex.synchronize do
        value, expires_at = @store[key]
        next nil if expires_at.nil?
        next value if expires_at > monotonic_now

        @store.delete(key)
        nil
      end
    end

    # @param key [String]
    # @param value [Object]
    # @param ttl [Numeric] seconds until the entry expires
    # @return [Object] the value that was stored
    def set(key, value, ttl)
      @mutex.synchronize { @store[key] = [value, monotonic_now + ttl] }
      value
    end

    # Drops every entry.
    # @return [void]
    def clear
      @mutex.synchronize { @store.clear }
    end

    private

    # Monotonic, so TTLs survive clock changes (NTP steps, DST).
    def monotonic_now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
