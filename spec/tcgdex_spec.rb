# frozen_string_literal: true

RSpec.describe TCGdex do
  it "has a semver version number" do
    expect(TCGdex::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end

  describe "configuration" do
    it "defaults to English" do
      expect(TCGdex.new.language).to eq("en")
    end

    it "takes the language positionally" do
      expect(TCGdex.new("fr").language).to eq("fr")
    end

    it "stores a symbol language as a string" do
      expect(TCGdex.new(:ja).language).to eq("ja")
    end

    it "defaults the endpoint to the v2 base, without a trailing slash" do
      expect(TCGdex.new.endpoint_url).to eq("https://api.tcgdex.net/v2")
    end

    it "exposes a shared Http transport" do
      expect(TCGdex.new.http).to be_a(TCGdex::Http)
    end

    it "delegates cache_ttl to the transport" do
      client = TCGdex.new
      client.cache_ttl = 600

      expect(client.cache_ttl).to eq(600)
      expect(client.http.cache_ttl).to eq(600)
    end

    it "defaults cache_ttl to one hour" do
      expect(TCGdex.new.cache_ttl).to eq(3600)
    end

    it "delegates the cache to the transport" do
      client = TCGdex.new
      client.cache = nil

      expect(client.http.cache).to be_nil
    end

    it "reads the cache back through the delegator" do
      expect(TCGdex.new.cache).to be_a(TCGdex::Cache)
    end

    it "gives each client its own cache" do
      expect(TCGdex.new.cache).not_to be(TCGdex.new.cache)
    end
  end

  describe "endpoint readers" do
    subject(:client) { TCGdex.new }

    TCGdex::ENDPOINTS.each do |name, (item_class, brief_class, path)|
      it "exposes ##{name} as an Endpoint for /#{path}" do
        endpoint = client.public_send(name)

        expect(endpoint).to be_a(TCGdex::Endpoint)
        expect(endpoint.instance_variable_get(:@path)).to eq(path)
        expect(endpoint.instance_variable_get(:@item_class)).to eq(item_class)
        expect(endpoint.instance_variable_get(:@brief_class)).to eq(brief_class)
      end
    end

    it "memoizes each endpoint" do
      first_reference = client.card

      expect(client.card).to be(first_reference)
    end

    it "wires all sixteen resources" do
      expect(TCGdex::ENDPOINTS.size).to eq(16)
    end
  end

  describe "#random" do
    subject(:client) { TCGdex.new("en", cache: nil) }

    it "fetches a random card" do
      stub_request(:get, "https://api.tcgdex.net/v2/en/random/card")
        .to_return(status: 200, body: fixture("card_full"))

      expect(client.random.card).to be_a(TCGdex::Card).and have_attributes(name: "Furret")
    end

    it "fetches a random set" do
      stub_request(:get, "https://api.tcgdex.net/v2/en/random/set")
        .to_return(status: 200, body: fixture("set_full_trimmed"))

      expect(client.random.set).to be_a(TCGdex::Set).and have_attributes(id: "swsh3")
    end

    it "fetches a random serie" do
      stub_request(:get, "https://api.tcgdex.net/v2/en/random/serie")
        .to_return(status: 200, body: fixture("serie_full_trimmed"))

      expect(client.random.serie).to be_a(TCGdex::Serie).and have_attributes(id: "swsh")
    end

    it "attaches the client to what it returns" do
      stub_request(:get, "https://api.tcgdex.net/v2/en/random/card")
        .to_return(status: 200, body: fixture("card_full"))

      expect(client.random.card.client).to be(client)
    end
  end

  describe "#fetch" do
    subject(:client) { TCGdex.new("en", cache: nil) }

    it "joins the segments under the language and returns parsed JSON" do
      stub_request(:get, "https://api.tcgdex.net/v2/en/sets/swsh3/136")
        .to_return(status: 200, body: fixture("card_full"))

      expect(client.fetch("sets", "swsh3", "136")).to be_a(Hash).and include("name" => "Furret")
    end

    it "returns nil on a 404" do
      stub_request(:get, "https://api.tcgdex.net/v2/en/sets/nope").to_return(status: 404, body: "")

      expect(client.fetch("sets", "nope")).to be_nil
    end

    it "appends a query when given one" do
      stub = stub_request(:get, "https://api.tcgdex.net/v2/en/cards?name=pika")
             .to_return(status: 200, body: "[]")

      client.fetch("cards", query: TCGdex::Query.new.contains(:name, "pika"))

      expect(stub).to have_been_requested
    end

    it "omits the query string for an empty query" do
      stub = stub_request(:get, "https://api.tcgdex.net/v2/en/cards")
             .to_return(status: 200, body: "[]")

      client.fetch("cards", query: TCGdex::Query.new)

      expect(stub).to have_been_requested
    end
  end

  describe "relationship helpers over the wire" do
    subject(:client) { TCGdex.new("en", cache: nil) }

    it "resolves CardBrief#full_card" do
      stub_request(:get, "https://api.tcgdex.net/v2/en/cards/swsh3-136")
        .to_return(status: 200, body: fixture("card_full"))
      brief = TCGdex::CardBrief.new({ "id" => "swsh3-136" }, client: client)

      expect(brief.full_card).to have_attributes(name: "Furret")
    end

    it "resolves SetBrief#full_set" do
      stub_request(:get, "https://api.tcgdex.net/v2/en/sets/swsh3")
        .to_return(status: 200, body: fixture("set_full_trimmed"))
      brief = TCGdex::SetBrief.new({ "id" => "swsh3" }, client: client)

      expect(brief.full_set).to have_attributes(name: "Darkness Ablaze")
    end

    it "resolves Set#card through /sets/{id}/{localId}" do
      stub_request(:get, "https://api.tcgdex.net/v2/en/sets/swsh3/136")
        .to_return(status: 200, body: fixture("card_full"))
      set = TCGdex::Set.new({ "id" => "swsh3" }, client: client)

      expect(set.card("136")).to have_attributes(id: "swsh3-136")
    end

    it "resolves CardBrief#image_data" do
      stub_request(:get, "https://assets.tcgdex.net/en/swsh/swsh3/136/high.png")
        .to_return(status: 200, body: "PNG")
      brief = TCGdex::CardBrief.new(
        { "id" => "swsh3-136", "image" => "https://assets.tcgdex.net/en/swsh/swsh3/136" },
        client: client
      )

      expect(brief.image_data).to eq("PNG")
    end
  end
end
