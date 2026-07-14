# frozen_string_literal: true

# The same card in several languages. Set the language per instance; a language
# a card is not translated into comes back as nil (a 404 from the API).
#
# Runnable against the live API:  ruby -Ilib examples/languages.rb

require "tcgdex"

%w[en fr de].each do |language|
  tcgdex = TCGdex.new(language)
  card = tcgdex.card.get("swsh3-136")
  puts "#{language}: #{card&.name || "(not translated)"}"
end
