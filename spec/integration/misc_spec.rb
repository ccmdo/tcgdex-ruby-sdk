# frozen_string_literal: true

RSpec.describe "Miscellaneous (integration)", :vcr do
  it "serves another language" do
    card = TCGdex.new("fr").card.get("swsh3-136")

    expect(card.name).to eq("Fouinar")
  end

  it "returns a random card of the right shape" do
    card = TCGdex.new("en").random.card

    expect(card).to be_a(TCGdex::Card)
    expect(card.id).to be_a(String)
  end

  it "returns nil for a card that does not exist" do
    expect(TCGdex.new("en").card.get("nonexistent-999")).to be_nil
  end

  it "reaches an endpoint through the low-level fetch escape hatch" do
    data = TCGdex.new("en").fetch("sets", "swsh3", "136")

    expect(data).to be_a(Hash).and include("name" => "Furret")
  end
end
