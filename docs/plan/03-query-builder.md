# Milestone 03 — Query builder

## Objective

`TCGdex::Query`: a chainable builder that emits exactly the REST params documented in
`api-reference.md` ("Filtering, sorting, pagination"). Pure Ruby, no HTTP — fully
unit-testable without stubs.

## Prerequisites

Milestone 01. (Independent of 02; can be done in the same session.)

## Method → emitted param table (the contract)

Every filter method takes `(key, value)`, appends one `[key, value]` pair to an internal
ordered list, and returns `self`. `key` accepts Symbol or String.

| Method | Emits | Alias of |
|---|---|---|
| `contains(key, value)` | `key=value` (laxist match; wildcards `*` pass through) | |
| `like(key, value)` | same | `contains` |
| `includes(key, value)` | same | `contains` |
| `not_contains(key, value)` | `key=not:value` | |
| `not_like(key, value)` | same | `not_contains` |
| `equal(key, value)` | `key=eq:value` | |
| `eq(key, value)` | same | `equal` |
| `not_equal(key, value)` | `key=neq:value` | |
| `neq(key, value)` | same | `not_equal` |
| `greater_than(key, n)` | `key=gt:n` | |
| `gt(key, n)` | same | `greater_than` |
| `greater_or_equal(key, n)` | `key=gte:n` | |
| `gte(key, n)` | same | `greater_or_equal` |
| `less_than(key, n)` | `key=lt:n` | |
| `lt(key, n)` | same | `less_than` |
| `less_or_equal(key, n)` | `key=lte:n` | |
| `lte(key, n)` | same | `less_or_equal` |
| `null(key)` | `key=null:` | |
| `not_null(key)` | `key=notnull:` | |
| `sort(key, order = :asc)` | `sort:field=key` AND `sort:order=ASC\|DESC` | order accepts `:asc/:desc/"ASC"/"DESC"` |
| `paginate(page:, items_per_page: 100)` | `pagination:page=page` AND `pagination:itemsPerPage=items_per_page` | |

Notes:
- Multi-value OR needs no special method: `equal(:name, "Furret|Pikachu")` — the `|` must
  survive encoding (see below).
- Duplicate keys are legal and order-preserved (e.g. `gte(:hp, 50).lte(:hp, 90)` →
  `hp=gte:50&hp=lte:90`).
- Use `alias_method` for the aliases so they show as such in docs.

## Emission API

```ruby
query.to_params   # => [["name", "eq:Furret"], ["sort:field", "hp"], ...] (unencoded pairs)
query.to_s        # => "name=eq%3AFurret&sort%3Afield=hp..." — encoded query string, NO leading "?"
```

`Endpoint#list` (milestone 05) will consume `to_params`/`to_s`. Prefer building the final
string with `URI.encode_www_form(pairs)` — it handles arrays of pairs, duplicate keys, and
encoding in one call. Verify in specs that:
- `|` encodes to `%7C` and the API still ORs correctly (it does — checked in milestone 06
  cassettes; encoded pipes are standard form encoding),
- `:` in values (`eq:Furret`) is form-encoded (that's fine; the API decodes),
- spaces become `+` or `%20` (either is accepted; `encode_www_form` yields `+`).

If live testing in milestone 06 shows the API mishandles `+` for spaces or `%7C` for pipes,
switch to `URI.encode_www_form_component` with `+`→`%20` post-processing and document it
here — the Python SDK effectively ships raw `|` and `%20`.

## Tasks

- [x] `lib/tcgdex/query.rb` per the tables above; require from `lib/tcgdex.rb`.
- [x] YARD docstrings with one example per method group.
- [x] `spec/tcgdex/query_spec.rb`: one spec per row of the method table (assert `to_params`
      pair emitted); chaining returns self; duplicate-key ordering; `to_s` encoding cases
      (pipe, colon, space, `?` in value, unicode e.g. "Pokémon"); `sort` normalizes
      `:desc` → `"DESC"`; `paginate` defaults `items_per_page: 100`; Symbol and String keys
      both work; empty query `to_s` → `""`.
- [x] Commit: `feat: add Query builder for filtering, sorting and pagination`.

## Acceptance criteria

`bundle exec rake` green. This exact expression works:

```ruby
TCGdex::Query.new.contains(:name, "pika").gte(:hp, 60).sort(:hp, :desc)
  .paginate(page: 1, items_per_page: 20).to_params
# => [["name", "pika"], ["hp", "gte:60"], ["sort:field", "hp"], ["sort:order", "DESC"],
#     ["pagination:page", 1], ["pagination:itemsPerPage", 20]]
```

## Out of scope

Sending queries over HTTP (milestone 05); validating field names against models.

## Handoff notes

Milestone complete. Interface is exactly as specified. Points worth knowing:

- Aliases use the `alias` keyword, not `alias_method` (RuboCop's `Style/Alias` default);
  YARD still renders them as "Also known as", which was the point.
- `sort` raises `ArgumentError` on an order other than asc/desc — the plan didn't specify
  a behaviour, and silently emitting a bogus `sort:order` seemed worse.
- `to_params` returns duplicated pairs, so callers can't mutate the query's internals.
- Pagination values stay Integers in `to_params` (`["pagination:page", 1]`); everything else
  is stringified by interpolation.
- **Still to confirm in milestone 06**: `URI.encode_www_form` renders spaces as `+` and the
  OR pipe as `%7C`. Believed fine; if a live cassette shows otherwise, switch to
  `encode_www_form_component` with `+`→`%20` post-processing and update this file and
  the "Emission API" section above.
- `.rubocop.yml` gained `Style/WordArray: MinSize: 3` so two-element `["key", "value"]`
  expectations stay bracketed instead of becoming `%w[key value]`.
