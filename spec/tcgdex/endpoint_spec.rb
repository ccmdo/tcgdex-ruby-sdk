# frozen_string_literal: true

RSpec.describe TCGdex::Endpoint do
  let(:client) { TCGdex.new("en", cache: nil) }

  describe "#get" do
    subject(:endpoint) { described_class.new(client, TCGdex::Card, TCGdex::CardBrief, "cards") }

    it "builds the url from endpoint, language and path" do
      stub = stub_request(:get, "https://api.tcgdex.net/v2/en/cards/swsh3-136")
             .to_return(status: 200, body: fixture("card_full"))

      endpoint.get("swsh3-136")

      expect(stub).to have_been_requested
    end

    it "wraps the response in the item model" do
      stub_request(:get, "https://api.tcgdex.net/v2/en/cards/swsh3-136")
        .to_return(status: 200, body: fixture("card_full"))

      expect(endpoint.get("swsh3-136")).to be_a(TCGdex::Card).and have_attributes(name: "Furret")
    end

    it "attaches the client to the returned model" do
      stub_request(:get, "https://api.tcgdex.net/v2/en/cards/swsh3-136")
        .to_return(status: 200, body: fixture("card_full"))

      expect(endpoint.get("swsh3-136").client).to be(client)
    end

    it "returns nil when the resource is missing" do
      stub_request(:get, "https://api.tcgdex.net/v2/en/cards/nope")
        .to_return(status: 404, body: fixture("error_404"))

      expect(endpoint.get("nope")).to be_nil
    end

    it "escapes spaces in an id but leaves pre-encoded characters alone" do
      stub = stub_request(:get, "https://api.tcgdex.net/v2/en/cards/exu-%3F")
             .to_return(status: 200, body: "{}")

      endpoint.get("exu-%3F")

      expect(stub).to have_been_requested
    end

    it "escapes spaces in index values" do
      endpoint = described_class.new(client, TCGdex::StringEndpoint, nil, "illustrators")
      stub = stub_request(:get, "https://api.tcgdex.net/v2/en/illustrators/tetsuya%20koizumi")
             .to_return(status: 200, body: '{"name":"tetsuya koizumi","cards":[]}')

      endpoint.get("tetsuya koizumi")

      expect(stub).to have_been_requested
    end

    it "follows a change of language at request time" do
      client.language = "fr"
      stub = stub_request(:get, "https://api.tcgdex.net/v2/fr/cards/swsh3-136")
             .to_return(status: 200, body: "{}")

      endpoint.get("swsh3-136")

      expect(stub).to have_been_requested
    end
  end

  describe "#list" do
    subject(:endpoint) { described_class.new(client, TCGdex::Card, TCGdex::CardBrief, "cards") }

    it "maps each element through the brief model" do
      stub_request(:get, "https://api.tcgdex.net/v2/en/cards")
        .to_return(status: 200, body: fixture("cards_list_page"))

      result = endpoint.list

      expect(result).to all(be_a(TCGdex::CardBrief))
      expect(result.map(&:name)).to eq(%w[Unown Unown])
    end

    it "attaches the client to every brief, so they can lazy-load" do
      stub_request(:get, "https://api.tcgdex.net/v2/en/cards")
        .to_return(status: 200, body: fixture("cards_list_page"))

      expect(endpoint.list.first.client).to be(client)
    end

    it "appends a non-empty query" do
      stub = stub_request(:get, "https://api.tcgdex.net/v2/en/cards?name=pika")
             .to_return(status: 200, body: "[]")

      endpoint.list(TCGdex::Query.new.contains(:name, "pika"))

      expect(stub).to have_been_requested
    end

    it "omits the query string for an empty query" do
      stub = stub_request(:get, "https://api.tcgdex.net/v2/en/cards")
             .to_return(status: 200, body: "[]")

      endpoint.list(TCGdex::Query.new)

      expect(stub).to have_been_requested
    end

    it "returns [] when the list endpoint 404s" do
      stub_request(:get, "https://api.tcgdex.net/v2/en/cards").to_return(status: 404, body: "")

      expect(endpoint.list).to eq([])
    end

    context "when the endpoint has no brief class (a String/Integer index)" do
      subject(:endpoint) { described_class.new(client, TCGdex::StringEndpoint, nil, "types") }

      it "returns the raw string array untouched" do
        stub_request(:get, "https://api.tcgdex.net/v2/en/types")
          .to_return(status: 200, body: fixture("types_list"))

        expect(endpoint.list).to start_with("Colorless", "Darkness")
      end

      it "returns raw integers for a numeric index" do
        endpoint = described_class.new(client, TCGdex::StringEndpoint, nil, "hp")
        stub_request(:get, "https://api.tcgdex.net/v2/en/hp")
          .to_return(status: 200, body: fixture("hp_list"))

        expect(endpoint.list).to start_with(10, 30, 40)
      end
    end
  end
end
