# frozen_string_literal: true

RSpec.describe TCGdex::CardBrief do
  let(:briefs) { parsed_fixture("cards_list_page").map { |data| described_class.new(data) } }
  let(:unown_question) { briefs[1] }
  let(:brief) do
    described_class.new({ "id" => "swsh3-136", "localId" => "136", "name" => "Furret",
                          "image" => "https://assets.tcgdex.net/en/swsh/swsh3/136" })
  end

  it "reads the scalar fields" do
    expect(brief).to have_attributes(id: "swsh3-136", local_id: "136", name: "Furret")
  end

  it "leaves a pre-encoded id exactly as the API sent it" do
    expect(unown_question).to have_attributes(id: "exu-%3F", local_id: "%3F", name: "Unown")
  end

  it "reads nil for a card the API gives no image" do
    expect(unown_question.image).to be_nil
  end

  describe "#image_url" do
    it "composes quality and extension onto the image base" do
      expect(brief.image_url(quality: :low, extension: :webp))
        .to eq("https://assets.tcgdex.net/en/swsh/swsh3/136/low.webp")
    end

    it "is nil when the card has no image" do
      expect(unown_question.image_url).to be_nil
    end

    it "rejects an unknown quality" do
      expect { brief.image_url(quality: :ultra) }.to raise_error(ArgumentError, /quality/)
    end
  end

  describe "#image_data" do
    let(:http) { double("http") }
    let(:client) { double("client", http: http) }

    it "downloads the image the url points at" do
      brief = described_class.new(brief_data, client: client)
      allow(http).to receive(:get_raw)
        .with("https://assets.tcgdex.net/en/swsh/swsh3/136/high.png").and_return("PNG")

      expect(brief.image_data).to eq("PNG")
    end

    it "raises when not attached to a client" do
      expect { brief.image_data }.to raise_error(TCGdex::Error, /not attached to a TCGdex client/)
    end
  end

  describe "#full_card" do
    it "fetches the full card by id" do
      card = instance_double(TCGdex::Card)
      endpoint = double("card endpoint")
      brief = described_class.new(brief_data, client: double("client", card: endpoint))
      allow(endpoint).to receive(:get).with("swsh3-136").and_return(card)

      expect(brief.full_card).to be(card)
    end

    it "raises when not attached to a client" do
      expect { brief.full_card }.to raise_error(TCGdex::Error, /not attached to a TCGdex client/)
    end
  end

  def brief_data
    { "id" => "swsh3-136", "localId" => "136", "name" => "Furret",
      "image" => "https://assets.tcgdex.net/en/swsh/swsh3/136" }
  end
end
