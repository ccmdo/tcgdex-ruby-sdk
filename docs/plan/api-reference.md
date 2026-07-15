# TCGdex API Reference (ground truth for the Ruby SDK)

Distilled from the official Python SDK (`tcgdex/python-sdk`, primary port reference), the
JavaScript SDK (`tcgdex/javascript-sdk`), the REST docs (https://tcgdex.dev/rest), and
**live API responses captured 2026-07-14** (samples in `docs/plan/fixtures/`).
Implementing sessions should NOT need to re-research any of this; if something here
contradicts the live API, trust the live API and update this file.

## Basics

- Base URL: `https://api.tcgdex.net/v2/{lang}` (HTTPS only; HTTP redirects).
- All requests are `GET`; responses are JSON.
- No authentication. Be a good citizen: send a `User-Agent: tcgdex-ruby-sdk/{VERSION}`
  header (both official SDKs do this) and cache responses (default TTL 1 hour in both SDKs —
  the JS SDK calls its cache "the system used by TCGdex to not kill the API").
- Dataset size (2026-07): ~23,323 cards, 214 sets, 21 series (English).
  An unpaginated `GET /cards` returns the full ~1.7 MB brief list — works, but prefer pagination.

## Languages (17)

`en`, `fr`, `es`, `es-mx`, `it`, `pt-br`, `pt-pt`, `de`, `nl`, `pl`, `ru`, `ja`, `ko`,
`zh-tw`, `zh-cn`, `id`, `th`

Not every card/set exists in every language (404s are normal for untranslated content).

## Endpoints

### Core resources

| Request | Returns |
|---|---|
| `GET /cards` | array of **CardBrief** |
| `GET /cards/{id}` | full **Card** (e.g. `swsh3-136`) |
| `GET /sets` | array of **SetBrief** |
| `GET /sets/{id}` | full **Set** (id or name, e.g. `swsh3`) |
| `GET /sets/{setId}/{localId}` | full **Card** by its set-local ID (e.g. `/sets/swsh3/136`) |
| `GET /series` | array of **SerieBrief** |
| `GET /series/{id}` | full **Serie** (e.g. `swsh`) |
| `GET /random/card` | full **Card** (random) |
| `GET /random/set` | full **Set** (random) |
| `GET /random/serie` | full **Serie** (random) |

### String endpoints (card-attribute indexes)

`GET /{endpoint}` returns an array of possible values (strings, or integers where noted).
`GET /{endpoint}/{value}` returns `{ "name": <value>, "cards": [CardBrief, ...] }`.

| URL path | Ruby accessor (planned) | List value type |
|---|---|---|
| `categories` | `category` | String |
| `dex-ids` | `dex_id` | Integer |
| `energy-types` | `energy_type` | String |
| `hp` | `hp` | Integer |
| `illustrators` | `illustrator` | String |
| `rarities` | `rarity` | String |
| `regulation-marks` | `regulation_mark` | String |
| `retreats` | `retreat` | Integer |
| `stages` | `stage` | String |
| `suffixes` | `suffix` | String |
| `trainer-types` | `trainer_type` | String |
| `types` | `type` | String |
| `variants` | `variant` | String |

**Live quirk (2026-07):** `/types/{value}` and `/hp/{value}` item lookups currently return
`"cards": []` regardless of value, while `/illustrators/{value}` and `/rarities/{value}`
return populated card lists. The returned `name` is lowercased (`Uncommon` → `uncommon`).
Don't treat empty `cards` as an SDK bug; use `rarities`/`illustrators` when recording
cassettes that need populated results.

## Filtering, sorting, pagination (query params on list endpoints)

Format: `field=value` where `field` is any JSON key of the (full) object.

| Filter | Syntax | Notes |
|---|---|---|
| Laxist contains (default) | `name=fu` or `name=like:fu` | partial, case-insensitive |
| Wildcards | `name=*chu`, `name=fu*` | anchor to end / start |
| Laxist negation | `name=not:fu` or `name=notlike:fu` | |
| Strict equality | `name=eq:Furret` | |
| Strict negation | `name=neq:Furret` | |
| Numeric compare | `hp=gte:50`, `hp=lte:50`, `hp=gt:50`, `hp=lt:50` | |
| Null / not null | `effect=null:`, `effect=notnull:` | trailing colon required |
| Multi-value OR | `name=eq:Furret\|Pikachu` | pipe-separated |

| Sorting / pagination | Syntax | Default |
|---|---|---|
| Sort field | `sort:field=name` | `releaseDate` > `localId` > `id` |
| Sort order | `sort:order=ASC` or `DESC` | `ASC` |
| Page | `pagination:page=3` | 1 |
| Page size | `pagination:itemsPerPage=20` | 100 once pagination is enabled |

Example: `GET /v2/en/cards?name=pika&hp=gte:60&sort:field=hp&sort:order=DESC&pagination:page=1&pagination:itemsPerPage=20`

## Asset URLs (images)

Image fields in responses are **base URLs without extension**; the client appends format info:

| Asset | Rule | Options |
|---|---|---|
| Card `image` | `{image}/{quality}.{extension}` | quality: `high`, `low`; extension: `png`, `jpg`, `webp` |
| Set/Serie `logo`, Set `symbol` | `{base}.{extension}` (no quality) | extension: `png`, `jpg`, `webp` |

`png`/`webp` have transparent backgrounds; `jpg` white.
Example: `https://assets.tcgdex.net/en/swsh/swsh3/136` → `.../136/high.png`.

## Errors

- `404` (missing resource or untranslated content): RFC-7807-style body
  (see `fixtures/error_404.json`):
  `{"type":"https://tcgdex.dev/errors/not-found","title":"...","status":404,"endpoint":"/en/cards/nonexistent-999","method":"GET"}`
- SDK semantics (matching JS SDK): non-200 that is not 5xx → return `nil`;
  `5xx` → raise `TCGdex::ServerError`; socket/timeout/DNS failures → raise `TCGdex::NetworkError`.
  Both inherit `TCGdex::Error`.

## Model field tables

Conventions for the Ruby port:
- JSON keys are camelCase; Ruby attributes are the **mechanical snake_case** conversion
  (`localId` → `local_id`, `dexId` → `dex_id`, `cardCount` → `card_count`). No exceptions, no pluralizing.
- `?` = nullable/absent. Models MUST tolerate unknown JSON keys (the API adds fields
  faster than the SDKs track them) and keep the raw parsed hash accessible via `#to_h`.

### Card (full) — `fixtures/card_full.json`

| JSON key | Ruby attr | Type | Notes |
|---|---|---|---|
| `id` | `id` | String | globally unique, `{setId}-{localId}` |
| `localId` | `local_id` | String | position within set |
| `name` | `name` | String | |
| `image` | `image` | String? | base URL, no extension |
| `category` | `category` | String | `Pokemon`, `Trainer`, `Energy` |
| `illustrator` | `illustrator` | String? | |
| `rarity` | `rarity` | String | |
| `variants` | `variants` | CardVariants | |
| `variants_detailed` | `variants_detailed` | VariantDetailed[]? | **live-only** (not in py/js SDKs; typed since 0.2.0); includes pricing |
| `set` | `set` | SetBrief | embedded resume of parent set |
| `dexId` | `dex_id` | Integer[]? | Pokédex IDs |
| `hp` | `hp` | Integer? | |
| `types` | `types` | String[]? | |
| `evolveFrom` | `evolve_from` | String? | |
| `description` | `description` | String? | |
| `level` | `level` | String? | can be `"X"` |
| `stage` | `stage` | String? | language-dependent |
| `suffix` | `suffix` | String? | |
| `item` | `item` | CardItem? | `{name, effect}` |
| `abilities` | `abilities` | CardAbility[]? | |
| `attacks` | `attacks` | CardAttack[]? | |
| `weaknesses` | `weaknesses` | WeakRes[]? | |
| `resistances` | `resistances` | WeakRes[]? | |
| `retreat` | `retreat` | Integer? | |
| `effect` | `effect` | String? | Trainer/Energy only |
| `trainerType` | `trainer_type` | String? | |
| `energyType` | `energy_type` | String? | |
| `regulationMark` | `regulation_mark` | String? | |
| `legal` | `legal` | Legal | `{standard, expanded}` booleans |
| `boosters` | `boosters` | Booster[]? | `null` = in every booster; `[]` = in none |
| `updated` | `updated` | String? | **live-only**, ISO-8601 timestamp |
| `pricing` | `pricing` | Pricing? | **live-only**, see Pricing below (typed since 0.2.0) |

### CardBrief (list item) — `fixtures/cards_list_page.json`

| JSON key | Ruby attr | Type |
|---|---|---|
| `id` | `id` | String |
| `localId` | `local_id` | String |
| `name` | `name` | String |
| `image` | `image` | String? |

### Set (full) — `fixtures/set_full_trimmed.json`

| JSON key | Ruby attr | Type | Notes |
|---|---|---|---|
| `id` | `id` | String | |
| `name` | `name` | String | |
| `logo` | `logo` | String? | base URL |
| `symbol` | `symbol` | String? | base URL |
| `cardCount` | `card_count` | CardCount | `{total, official, normal?, reverse?, holo?, firstEd?}` |
| `serie` | `serie` | SerieBrief | |
| `tcgOnline` | `tcg_online` | String? | TCG Online code |
| `releaseDate` | `release_date` | String | `yyyy-mm-dd` |
| `legal` | `legal` | Legal | |
| `cards` | `cards` | CardBrief[] | |
| `boosters` | `boosters` | Booster[]? | |
| `abbreviation` | `abbreviation` | Abbreviation? | **live key is singular** `{official?, localized?}`; the Python SDK models an outdated plural `abbreviations` — follow the live API |

### SetBrief — `fixtures/sets_list_trimmed.json`

| JSON key | Ruby attr | Type |
|---|---|---|
| `id` | `id` | String |
| `name` | `name` | String |
| `logo` | `logo` | String? |
| `symbol` | `symbol` | String? |
| `cardCount` | `card_count` | CardCountBrief `{total, official}` |

### Serie (full) — `fixtures/serie_full_trimmed.json`

| JSON key | Ruby attr | Type | Notes |
|---|---|---|---|
| `id` | `id` | String | |
| `name` | `name` | String | |
| `logo` | `logo` | String? | base URL |
| `sets` | `sets` | SetBrief[] | |
| `firstSet` | `first_set` | SetBrief? | **live-only** (not in py/js SDKs) |
| `lastSet` | `last_set` | SetBrief? | **live-only** |
| `releaseDate` | `release_date` | String? | **live-only** |

### SerieBrief — `fixtures/series_list_trimmed.json`

`id` (String), `name` (String), `logo` (String?) — note `logo` genuinely absent for some
series (e.g. `misc`).

### StringEndpoint item — `fixtures/illustrator_item_trimmed.json`

`name` (String — echoed value, lowercased by the API), `cards` (CardBrief[]).

### Sub-structures

| Struct | Fields (JSON key → type) |
|---|---|
| **CardVariants** | `normal` bool, `reverse` bool, `holo` bool, `firstEdition` bool, `wPromo` bool |
| **CardAttack** | `name` String?, `cost` String[]?, `effect` String?, `damage` Integer-or-String? (e.g. `90` or `"x20"`) |
| **CardAbility** | `type` String, `name` String?, `effect` String? |
| **CardItem** | `name` String?, `effect` String? |
| **WeakRes** (weakness/resistance) | `type` String, `value` String? (e.g. `"×2"`, `"-30"`) |
| **Legal** | `standard` bool, `expanded` bool |
| **CardCount** (full) | `total` int, `official` int, `normal` int?, `reverse` int?, `holo` int?, `firstEd` int? |
| **CardCountBrief** | `total` int, `official` int |
| **Booster** | `id` String, `name` String, `logo` String?, `artwork_front` String?, `artwork_back` String? (already snake_case in JSON) |
| **Abbreviation** | `official` String? (Python SDK also lists per-language keys `fr`, `de`, …) |
| **VariantDetailed** | `type` String (`normal`/`reverse`/`holo`…), `size` String, `variantId` String, `subType` String?, `stamp` String[]?, `foil` String? (last three per the Swift SDK; special printings only), `pricing` Pricing? |
| **Pricing** (typed since 0.2.0) | `cardmarket` PricingCardmarket?, `tcgplayer` PricingTcgplayer? |
| **PricingCardmarket** | `updated` String, `unit` String (currency), `idProduct` Integer, `avg`/`low`/`trend`/`avg1`/`avg7`/`avg30` Float?, plus foil twins under hyphenated keys `avg-holo`/`low-holo`/`trend-holo`/`avg1-holo`/`avg7-holo`/`avg30-holo` → `avg_holo` etc. `idProduct` is live-verified but missing from the Kotlin/Swift SDKs |
| **PricingTcgplayer** | `updated` String, `unit` String (currency), printing slots (each PricingTcgplayerVariant?): `normal`, `holofoil`, `"reverse-holofoil"` → `reverse_holofoil`, `"1st-edition"` → `first_edition`, `"1st-edition-holofoil"` → `first_edition_holofoil`, `unlimited`, `"unlimited-holofoil"` → `unlimited_holofoil`. (Kotlin SDK's `holoFoil` lacks a `@SerializedName` and reads a key the API never sends — the live key is `holofoil`) |
| **PricingTcgplayerVariant** | `productId` Integer, `lowPrice`/`midPrice`/`highPrice`/`marketPrice`/`directLowPrice` Float? — `productId` is live-verified but missing from the Kotlin/Swift SDKs |

## Gotchas (hard-won; do not rediscover)

1. **Unknown keys**: the live API returns fields no SDK models yet (`variants_detailed`,
   `pricing`, `updated`, serie `firstSet`/`lastSet`). Model construction must ignore
   unrecognized keys and never raise; keep raw hash for `#to_h`.
2. **Pre-encoded IDs**: card IDs can contain percent-encoded chars as data — Unown "?" is
   `"id": "exu-%3F"` in list responses (see `fixtures/cards_list_page.json`). `get(id)`
   must escape **spaces only** (`' '` → `%20`, matching the Python SDK); do not
   re-encode `%` or the pre-encoded IDs break.
3. **`series` vs `serie`**: the URL path is `series`, the JSON key on Set is `serie`.
4. **String-endpoint values with spaces** work when escaped: `/illustrators/tetsuya%20koizumi`.
5. **Types/HP item lookups return empty `cards`** on the live API right now (see above).
6. **Booster semantics**: on Card, `boosters: null` means "available in every booster of the
   set", `[]` means "not in any booster".
7. **404 is a normal outcome** (bad id, or content not translated into the requested
   language) — return `nil`, don't raise.
8. **Damage is polymorphic**: usually Integer, sometimes String multiplier (`"x20"`, `"20+"`).
9. Default sort is `releaseDate` then `localId` then `id`; list order is stable enough to
   paginate.

## Reference SDK sources (for porting questions, not required reading)

- Python (primary): `https://raw.githubusercontent.com/tcgdex/python-sdk/master/src/tcgdexsdk/`
  `tcgdex.py`, `query.py`, `utils.py`, `enums.py`, `endpoints/Endpoint.py`, `models/*.py`
- JavaScript: `https://raw.githubusercontent.com/tcgdex/javascript-sdk/master/src/`
  `tcgdex.ts`, `Query.ts`, `interfaces.d.ts`, `models/*.ts`
- REST docs: https://tcgdex.dev/rest, https://tcgdex.dev/rest/filtering-sorting-pagination
