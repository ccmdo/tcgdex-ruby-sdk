# frozen_string_literal: true

RSpec.describe TCGdex::Serie do
  subject(:serie) { described_class.new(parsed_fixture("serie_full_trimmed")) }

  describe "attributes" do
    it "reads the scalar fields" do
      expect(serie).to have_attributes(id: "swsh", name: "Sword & Shield", release_date: "2019-11-15")
    end

    it "casts the sets it contains" do
      expect(serie.sets.map(&:id)).to eq(%w[swshp swsh1 swsh2])
    end

    it "casts each set as a brief, card count and all" do
      expect(serie.sets.first).to be_a(TCGdex::SetBrief)
      expect(serie.sets.first.card_count.total).to eq(307)
    end

    it "casts the live-only first and last set" do
      expect([serie.first_set, serie.last_set]).to all(be_a(TCGdex::SetBrief))
      expect(serie.last_set.name).to eq("Crown Zenith")
    end
  end

  describe "#logo_url" do
    it "appends the extension, with no quality" do
      expect(serie.logo_url).to eq("https://assets.tcgdex.net/en/swsh/swsh1/logo.png")
    end

    it "is nil for a serie with no logo" do
      expect(described_class.new({ "id" => "misc" }).logo_url).to be_nil
    end

    it "rejects an unknown extension" do
      expect { serie.logo_url(:gif) }.to raise_error(ArgumentError, /extension must be one of/)
    end
  end
end
