# frozen_string_literal: true

RSpec.describe TCGdex::SerieBrief do
  let(:briefs) { parsed_fixture("series_list_trimmed").map { |data| described_class.new(data) } }
  let(:base) { briefs.first }
  let(:misc) { briefs[1] }

  it "reads the scalar fields" do
    expect(base).to have_attributes(id: "base", name: "Base")
  end

  it "builds the logo url" do
    expect(base.logo_url(:jpg)).to eq("https://assets.tcgdex.net/en/base/base1/logo.jpg")
  end

  it "reads nil for a serie that genuinely has no logo" do
    expect(misc).to have_attributes(id: "misc", logo: nil)
  end

  it "has no logo url for a serie with no logo" do
    expect(misc.logo_url).to be_nil
  end

  describe "#full_serie" do
    it "fetches the full serie by id" do
      serie = instance_double(TCGdex::Serie)
      endpoint = double("serie endpoint")
      brief = described_class.new({ "id" => "swsh" }, client: double("client", serie: endpoint))
      allow(endpoint).to receive(:get).with("swsh").and_return(serie)

      expect(brief.full_serie).to be(serie)
    end

    it "raises when not attached to a client" do
      expect { base.full_serie }.to raise_error(TCGdex::Error, /not attached to a TCGdex client/)
    end
  end
end
