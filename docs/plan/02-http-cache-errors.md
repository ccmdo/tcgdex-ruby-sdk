# Milestone 02 — HTTP client, cache, errors

## Objective

The single transport path every endpoint will use: `TCGdex::Http` (Net::HTTP GET →
parsed JSON or nil), backed by `TCGdex::Cache` (thread-safe in-memory TTL) and the
`TCGdex::Error` hierarchy. Fully unit-tested with WebMock. No public-facing SDK surface yet.

## Prerequisites

Milestone 01 (scaffold). Read the **Errors** and **Basics** sections of `api-reference.md`.

## Tasks

- [ ] `lib/tcgdex/errors.rb`:
      `TCGdex::Error < StandardError`;
      `TCGdex::ServerError < Error` (carries `status` and raw `body` readers);
      `TCGdex::NetworkError < Error` (carries `cause` per Ruby's built-in cause chaining).
- [ ] `lib/tcgdex/cache.rb` — see sketch.
- [ ] `lib/tcgdex/http.rb` — see sketch.
- [ ] Specs: `spec/tcgdex/cache_spec.rb`, `spec/tcgdex/http_spec.rb` (WebMock).
- [ ] Require the new files from `lib/tcgdex.rb`.
- [ ] Commit: `feat: add HTTP transport, TTL cache and error hierarchy`.

## Design contract

### `TCGdex::Cache`

```ruby
class TCGdex
  class Cache
    def initialize            # {} store + Mutex
    def get(key)              # value or nil; expired entries deleted on read
    def set(key, value, ttl)  # ttl in seconds; store [value, monotonic_now + ttl]
    def clear
  end
end
```

- Use `Process.clock_gettime(Process::CLOCK_MONOTONIC)` — never `Time.now` (DST/NTP-proof).
- All three operations Mutex-guarded.
- This is a duck type: anything with `get`/`set` works as a replacement (documented in
  milestone 05 when it becomes user-visible config). Don't build an interface/module for it.
- Keep it dumb: no max-size/LRU (out of scope, note in YARD that unbounded growth is
  possible for very long-lived processes).

### `TCGdex::Http`

```ruby
class TCGdex
  class Http
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 30

    def initialize(cache: Cache.new, cache_ttl: 3600)
    attr_accessor :cache, :cache_ttl   # cache = nil disables caching

    # Returns parsed JSON (Hash/Array/String/Integer...), or nil for non-200 non-5xx.
    # Raises ServerError on 5xx, NetworkError on transport failures.
    def get(url)
  end
end
```

Behavior of `get(url)`:

1. If `cache` is set, return the cached parsed value on hit (key = full URL string).
2. `Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout:, read_timeout:)`,
   request with header `"User-Agent" => "tcgdex-ruby-sdk/#{TCGdex::VERSION}"`.
3. Response mapping (mirrors the JS SDK — see api-reference.md "Errors"):
   - `2xx` → `JSON.parse(body)`, store in cache with `cache_ttl`, return it.
   - `5xx` → raise `ServerError.new("TCGdex API server error (#{code})", status:, body:)`.
   - anything else (404 = missing/untranslated resource, etc.) → `nil`. Do NOT cache nils.
4. Rescue `SocketError, Timeout::Error, Errno::ECONNREFUSED, Errno::ECONNRESET,
   OpenSSL::SSL::SSLError, EOFError` → raise `NetworkError`, preserving `cause`
   (`raise NetworkError, "..."` inside the rescue keeps the chain automatically).
   Let `JSON::ParserError` propagate wrapped in `Error` with a clear message.

No redirects handling needed (API is HTTPS-only and doesn't redirect within v2); no retry
logic (out of scope for 0.1).

## Test checklist (WebMock; no VCR yet)

- 200 → parsed Hash returned; UA header asserted (`with(headers: {"User-Agent" => ...})`).
- 200 array body → parsed Array.
- 404 → nil (stub body with `fixtures/error_404.json` shape).
- 503 → raises `ServerError`, exposes status/body.
- Timeout (`to_timeout`) → `NetworkError`; connection refused (`to_raise(Errno::ECONNREFUSED)`)
  → `NetworkError` with cause set.
- Malformed JSON on 200 → `TCGdex::Error`.
- Cache: second `get` of same URL performs **no** second HTTP request (WebMock
  `assert_requested ..., times: 1`); expired TTL re-fetches (inject a tiny ttl and sleep,
  or better: stub the monotonic clock); `cache = nil` always re-fetches; 404s are not cached.
- Cache thread-safety smoke: N threads hammering get/set on one Cache — no exceptions.

## Acceptance criteria

`bundle exec rake` green. `TCGdex::Http.new.get(...)` is the only place in the codebase
that touches Net::HTTP (later milestones must go through it).

## Out of scope

Endpoint/model/query classes; retries; connection pooling/keep-alive; configurable
timeouts (constants are fine for 0.1); pluggable-cache docs (milestone 05).

## Handoff notes

(fill in only if stopping mid-milestone)
