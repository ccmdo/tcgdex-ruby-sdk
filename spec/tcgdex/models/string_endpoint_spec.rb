# frozen_string_literal: true

RSpec.describe TCGdex::StringEndpoint do
  subject(:item) { described_class.new(parsed_fixture("illustrator_item_trimmed")) }

  it "reads the value the API echoes back, lowercased as it sends it" do
    expect(item.name).to eq("tetsuya koizumi")
  end

  it "casts the cards carrying that value" do
    expect(item.cards.map(&:id)).to eq(%w[sm7.5-1 sm115-1 A4-005])
  end

  it "casts each card as a brief" do
    expect(item.cards).to all(be_a(TCGdex::CardBrief))
  end

  it "builds image urls for the cards that have images" do
    expect(item.cards[1].image_url).to eq("https://assets.tcgdex.net/en/sm/sm115/1/high.png")
  end

  it "copes with an empty card list, as types and hp lookups return" do
    expect(described_class.new({ "name" => "colorless", "cards" => [] }).cards).to eq([])
  end
end
