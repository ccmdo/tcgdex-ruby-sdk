# frozen_string_literal: true

RSpec.describe TCGdex::Set do
  subject(:set) { described_class.new(parsed_fixture("set_full_trimmed")) }

  describe "attributes" do
    it "reads the scalar fields" do
      expect(set).to have_attributes(
        id: "swsh3",
        name: "Darkness Ablaze",
        tcg_online: "DAA",
        release_date: "2020-08-14"
      )
    end

    it "casts the full card count, breakdown and all" do
      expect(set.card_count).to be_a(TCGdex::CardCount).and have_attributes(
        total: 201, official: 189, normal: 138, reverse: 157, holo: 69, first_ed: 0
      )
    end

    it "casts the serie resume, from the singular key" do
      expect(set.serie).to be_a(TCGdex::SerieBrief)
        .and have_attributes(id: "swsh", name: "Sword & Shield")
    end

    it "casts the legality" do
      expect(set.legal).to be_a(TCGdex::Legal).and have_attributes(standard: false, expanded: true)
    end

    it "casts the card resumes" do
      expect(set.cards.map(&:name)).to eq(["Butterfree V", "Butterfree VMAX", "Paras"])
    end

    it "casts each card as a brief" do
      expect(set.cards.first).to be_a(TCGdex::CardBrief).and have_attributes(id: "swsh3-1", local_id: "1")
    end

    it "casts the abbreviation from the singular live key" do
      expect(set.abbreviation).to be_a(TCGdex::Abbreviation).and have_attributes(official: "DAA")
    end
  end

  describe "asset urls" do
    it "appends the extension to the logo, with no quality" do
      expect(set.logo_url).to eq("https://assets.tcgdex.net/en/swsh/swsh3/logo.png")
    end

    it "appends the extension to the symbol" do
      expect(set.symbol_url(:webp)).to eq("https://assets.tcgdex.net/univ/swsh/swsh3/symbol.webp")
    end

    it "is nil when the set has no logo" do
      expect(described_class.new({ "id" => "x" }).logo_url).to be_nil
    end

    it "rejects an unknown extension" do
      expect { set.logo_url(:gif) }.to raise_error(ArgumentError, /extension must be one of/)
    end
  end

  describe "#card" do
    let(:client) { double("client") }

    it "fetches a full card by the id printed on it" do
      set = described_class.new(parsed_fixture("set_full_trimmed"), client: client)
      allow(client).to receive(:fetch).with("sets", "swsh3", "136").and_return(parsed_fixture("card_full"))

      expect(set.card("136")).to be_a(TCGdex::Card).and have_attributes(id: "swsh3-136")
    end

    it "accepts an integer local id" do
      set = described_class.new(parsed_fixture("set_full_trimmed"), client: client)
      allow(client).to receive(:fetch).with("sets", "swsh3", "136").and_return(parsed_fixture("card_full"))

      expect(set.card(136)).to have_attributes(name: "Furret")
    end

    it "attaches the client to the card it builds" do
      set = described_class.new(parsed_fixture("set_full_trimmed"), client: client)
      allow(client).to receive(:fetch).and_return(parsed_fixture("card_full"))

      expect(set.card("136").client).to be(client)
    end

    it "is nil when the set has no such card" do
      set = described_class.new(parsed_fixture("set_full_trimmed"), client: client)
      allow(client).to receive(:fetch).and_return(nil)

      expect(set.card("999")).to be_nil
    end

    it "raises when the set is not attached to a client" do
      expect { set.card("136") }.to raise_error(TCGdex::Error, /not attached to a TCGdex client/)
    end
  end
end
