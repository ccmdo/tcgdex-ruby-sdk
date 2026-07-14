# frozen_string_literal: true

# Search cards with a filtered, sorted, paginated query, then hydrate one brief
# into its full card.
#
# Runnable against the live API:  ruby -Ilib examples/search.rb

require "tcgdex"

tcgdex = TCGdex.new("en")

query = TCGdex::Query.new
                     .contains(:name, "pikachu")
                     .gte(:hp, 60)
                     .sort(:hp, :desc)
                     .paginate(page: 1, items_per_page: 5)

cards = tcgdex.card.list(query)
puts "Found #{cards.size} briefs on this page:"
cards.each { |brief| puts "  - #{brief.name} (#{brief.id})" }
puts

# Briefs are lightweight; fetch the full card only when you need its details.
full = cards.first.full_card
puts "First result, hydrated: #{full.name} — HP #{full.hp}, rarity #{full.rarity}"
