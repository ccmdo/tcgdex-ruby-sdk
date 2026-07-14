# frozen_string_literal: true

RSpec.describe "String endpoints (integration)", :vcr do
  let(:client) { TCGdex.new("en") }

  # reader, value_class, sample value, cards populated? (types/hp/etc. return [] live).
  # Values are chosen for low card counts so the recorded cassettes stay small.
  cases = [
    [:category, String, "Energy", false],
    [:dex_id, Integer, "1025", false],
    [:energy_type, String, "Special", false],
    [:hp, Integer, "330", false],
    [:illustrator, String, "tetsuya koizumi", true],
    [:rarity, String, "ACE SPEC Rare", true],
    [:regulation_mark, String, "None", false],
    [:retreat, Integer, "4", false],
    [:stage, String, "BREAK", false],
    [:suffix, String, "Legend", false],
    [:trainer_type, String, "Stadium", false],
    [:type, String, "Colorless", false],
    [:variant, String, "wPromo", false]
  ]

  cases.each do |reader, value_class, value, cards_populated|
    describe "##{reader}" do
      it "lists raw #{value_class} values" do
        values = client.public_send(reader).list

        expect(values).to be_a(Array)
        expect(values).not_to be_empty
        expect(values.first).to be_a(value_class)
      end

      it "gets the #{value.inspect} item as a StringEndpoint" do
        item = client.public_send(reader).get(value)

        expect(item).to be_a(TCGdex::StringEndpoint)
        expect(item.name).not_to be_nil
        expect(item.cards).to all(be_a(TCGdex::CardBrief))
      end

      if cards_populated
        it "returns a populated card list for #{value.inspect}" do
          expect(client.public_send(reader).get(value).cards).not_to be_empty
        end
      end
    end
  end
end
