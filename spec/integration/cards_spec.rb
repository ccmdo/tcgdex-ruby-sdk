# frozen_string_literal: true

# Recorded against the live API (see spec/cassettes). Replays offline; re-record by
# deleting the relevant cassette and running with a live network.
RSpec.describe "Cards (integration)", :vcr do
  let(:client) { TCGdex.new("en") }

  describe "#get" do
    subject(:card) { client.card.get("swsh3-136") }

    it "returns the full card" do
      expect(card).to be_a(TCGdex::Card).and have_attributes(name: "Furret", hp: 110)
    end

    it "parses the attacks" do
      expect(card.attacks.map(&:name)).to include("Tail Smash")
    end

    it "carries the embedded set resume" do
      expect(card.set).to be_a(TCGdex::SetBrief).and have_attributes(id: "swsh3")
    end
  end

  describe "#list" do
    subject(:cards) { client.card.list(TCGdex::Query.new.paginate(page: 1, items_per_page: 2)) }

    it "returns a page of card briefs" do
      expect(cards).to all(be_a(TCGdex::CardBrief))
    end

    it "keeps the page small" do
      expect(cards.size).to eq(2)
    end

    it "gives each brief an id, local id and name" do
      expect(cards.first).to have_attributes(
        id: be_a(String), local_id: be_a(String), name: be_a(String)
      )
    end

    it "traverses from a brief to its full card" do
      expect(cards.first.full_card).to be_a(TCGdex::Card).and have_attributes(id: cards.first.id)
    end
  end
end
