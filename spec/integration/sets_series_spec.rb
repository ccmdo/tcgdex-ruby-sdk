# frozen_string_literal: true

RSpec.describe "Sets and series (integration)", :vcr do
  let(:client) { TCGdex.new("en") }

  describe "sets" do
    it "gets a full set with its card count, cards, serie and legality" do
      set = client.set.get("swsh3")

      expect(set).to be_a(TCGdex::Set)
      expect(set.card_count.official).to eq(189)
      expect(set.cards).to all(be_a(TCGdex::CardBrief))
      expect(set.serie).to be_a(TCGdex::SerieBrief).and have_attributes(id: "swsh")
      expect(set.legal).to be_a(TCGdex::Legal)
    end

    it "lists set briefs carrying a card count" do
      sets = client.set.list(TCGdex::Query.new.paginate(page: 1, items_per_page: 2))

      expect(sets).to all(be_a(TCGdex::SetBrief))
      expect(sets.first.card_count).to be_a(TCGdex::CardCountBrief)
    end

    it "fetches one card by its set-local id" do
      set = client.set.get("swsh3")

      expect(set.card("136")).to be_a(TCGdex::Card).and have_attributes(id: "swsh3-136")
    end

    it "traverses from a set brief to its full set" do
      sets = client.set.list(TCGdex::Query.new.paginate(page: 1, items_per_page: 2))

      expect(sets.first.full_set).to be_a(TCGdex::Set).and have_attributes(id: sets.first.id)
    end
  end

  describe "series" do
    it "gets a full serie, tolerating the live-only first/last set fields" do
      serie = client.serie.get("swsh")

      expect(serie).to be_a(TCGdex::Serie)
      expect(serie.sets).to all(be_a(TCGdex::SetBrief))
      expect(serie.first_set).to be_a(TCGdex::SetBrief)
      expect(serie.last_set).to be_a(TCGdex::SetBrief)
    end

    it "lists serie briefs" do
      series = client.serie.list(TCGdex::Query.new.paginate(page: 1, items_per_page: 2))

      expect(series).to all(be_a(TCGdex::SerieBrief))
    end

    it "traverses from a serie brief to its full serie" do
      series = client.serie.list(TCGdex::Query.new.paginate(page: 1, items_per_page: 2))

      expect(series.first.full_serie).to be_a(TCGdex::Serie).and have_attributes(id: series.first.id)
    end
  end
end
