# frozen_string_literal: true

RSpec.describe TCGdex::SetBrief do
  let(:briefs) { parsed_fixture("sets_list_trimmed").map { |data| described_class.new(data) } }
  let(:base1) { briefs.first }
  let(:jungle) { briefs[1] }

  it "reads the scalar fields" do
    expect(base1).to have_attributes(id: "base1", name: "Base Set")
  end

  it "casts the brief card count" do
    expect(base1.card_count).to be_a(TCGdex::CardCountBrief)
      .and have_attributes(total: 102, official: 102)
  end

  it "builds the logo url" do
    expect(base1.logo_url).to eq("https://assets.tcgdex.net/en/base/base1/logo.png")
  end

  it "builds the symbol url" do
    expect(jungle.symbol_url(:webp)).to eq("https://assets.tcgdex.net/univ/base/base2/symbol.webp")
  end

  it "has no symbol url when the set carries no symbol" do
    expect(base1.symbol_url).to be_nil
  end

  describe "#full_set" do
    it "fetches the full set by id" do
      set = instance_double(TCGdex::Set)
      endpoint = double("set endpoint")
      brief = described_class.new({ "id" => "base1" }, client: double("client", set: endpoint))
      allow(endpoint).to receive(:get).with("base1").and_return(set)

      expect(brief.full_set).to be(set)
    end

    it "raises when not attached to a client" do
      expect { base1.full_set }.to raise_error(TCGdex::Error, /not attached to a TCGdex client/)
    end
  end
end
