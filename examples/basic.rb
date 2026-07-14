# frozen_string_literal: true

# Fetch a single card and print a few of its fields.
#
# Runnable against the live API:  ruby -Ilib examples/basic.rb

require "tcgdex"

tcgdex = TCGdex.new("en")

card = tcgdex.card.get("swsh3-136")

puts "#{card.name} (#{card.id})"
puts "HP: #{card.hp}"
puts "Illustrator: #{card.illustrator}"
puts "Image: #{card.image_url(quality: :high, extension: :png)}"
puts

puts "Attacks:"
card.attacks.each do |attack|
  cost = attack.cost&.join(", ")
  puts "  - #{attack.name} [#{cost}] #{attack.damage}"
  puts "    #{attack.effect}" if attack.effect
end
