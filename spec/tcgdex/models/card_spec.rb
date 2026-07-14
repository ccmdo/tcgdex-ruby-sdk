# frozen_string_literal: true

RSpec.describe TCGdex::Card do
  subject(:card) { described_class.new(parsed_fixture("card_full")) }

  describe "attributes" do
    it "reads the scalar fields" do
      expect(card).to have_attributes(
        id: "swsh3-136",
        local_id: "136",
        name: "Furret",
        category: "Pokemon",
        illustrator: "tetsuya koizumi",
        rarity: "Uncommon"
      )
    end

    it "reads the Pokémon fields" do
      expect(card).to have_attributes(
        hp: 110,
        types: ["Colorless"],
        evolve_from: "Sentret",
        stage: "Stage1",
        retreat: 1,
        regulation_mark: "D"
      )
    end

    it "keeps dexId an array, without pluralizing the name" do
      expect(card.dex_id).to eq([162])
    end

    it "reads nil for fields this card does not carry" do
      expect(card).to have_attributes(level: nil, suffix: nil, effect: nil, trainer_type: nil,
                                      energy_type: nil, item: nil, abilities: nil, resistances: nil)
    end

    it "treats a null boosters list as 'in every booster of the set'" do
      expect(card.boosters).to be_nil
    end
  end

  describe "nested models" do
    it "casts the set resume" do
      expect(card.set).to be_a(TCGdex::SetBrief)
        .and have_attributes(id: "swsh3", name: "Darkness Ablaze")
    end

    it "casts the set's card count" do
      expect(card.set.card_count).to be_a(TCGdex::CardCountBrief)
        .and have_attributes(total: 201, official: 189)
    end

    it "casts the variants" do
      expect(card.variants).to be_a(TCGdex::CardVariants).and have_attributes(
        normal: true, reverse: true, holo: false, first_edition: false, w_promo: false
      )
    end

    it "casts the attacks" do
      expect(card.attacks.map(&:name)).to eq(["Feelin' Fine", "Tail Smash"])
    end

    it "reads an attack's cost and effect" do
      expect(card.attacks.first).to be_a(TCGdex::CardAttack)
        .and have_attributes(cost: ["Colorless"], effect: "Draw 3 cards.", damage: nil)
    end

    it "reads damage where an attack deals it" do
      expect(card.attacks[1].damage).to eq(90)
    end

    it "casts the weaknesses, modifier and all" do
      expect(card.weaknesses.first).to be_a(TCGdex::WeakRes)
        .and have_attributes(type: "Fighting", value: "×2")
    end

    it "casts the legality" do
      expect(card.legal).to be_a(TCGdex::Legal).and have_attributes(standard: false, expanded: true)
    end
  end

  describe "live-only fields" do
    it "reads the update timestamp" do
      expect(card.updated).to eq("2026-07-01T21:27:44+01:00")
    end

    it "leaves pricing as a raw hash, hyphenated keys intact" do
      expect(card.pricing["cardmarket"]["avg-holo"]).to eq(0.31)
    end

    it "leaves variants_detailed as raw hashes, reading its snake_case key" do
      expect(card.variants_detailed.map { |variant| variant["type"] }).to eq(%w[normal reverse])
    end

    it "keeps unmodeled data reachable through to_h" do
      expect(card.to_h).to include("variants_detailed", "pricing", "updated")
    end
  end

  describe "#image_url" do
    it "defaults to high quality png" do
      expect(card.image_url).to eq("https://assets.tcgdex.net/en/swsh/swsh3/136/high.png")
    end

    it "composes the quality and extension asked for" do
      expect(card.image_url(quality: :low, extension: :webp))
        .to eq("https://assets.tcgdex.net/en/swsh/swsh3/136/low.webp")
    end

    it "accepts strings as readily as symbols" do
      expect(card.image_url(quality: "low", extension: "jpg"))
        .to eq("https://assets.tcgdex.net/en/swsh/swsh3/136/low.jpg")
    end

    it "is nil for a card with no image" do
      expect(described_class.new({ "id" => "x" }).image_url).to be_nil
    end

    it "rejects an unknown quality" do
      expect { card.image_url(quality: :medium) }
        .to raise_error(ArgumentError, /quality must be one of high, low/)
    end

    it "rejects an unknown extension" do
      expect { card.image_url(extension: :gif) }
        .to raise_error(ArgumentError, /extension must be one of png, jpg, webp/)
    end
  end

  describe "#image_data" do
    let(:http) { double("http") }
    let(:client) { double("client", http: http) }

    it "downloads the image the url points at" do
      card = described_class.new(parsed_fixture("card_full"), client: client)
      allow(http).to receive(:get_raw)
        .with("https://assets.tcgdex.net/en/swsh/swsh3/136/high.png").and_return("PNG")

      expect(card.image_data).to eq("PNG")
    end

    it "is nil for a card with no image, without calling out" do
      card = described_class.new({ "id" => "x" }, client: client)

      expect(card.image_data).to be_nil
    end

    it "raises when the card is not attached to a client" do
      expect { card.image_data }
        .to raise_error(TCGdex::Error, /not attached to a TCGdex client/)
    end
  end

  describe "#full_set" do
    let(:set) { instance_double(TCGdex::Set) }
    let(:set_endpoint) { double("set endpoint") }
    let(:client) { double("client", set: set_endpoint) }

    it "fetches the parent set by id" do
      card = described_class.new(parsed_fixture("card_full"), client: client)
      allow(set_endpoint).to receive(:get).with("swsh3").and_return(set)

      expect(card.full_set).to be(set)
    end

    it "is nil for a card with no set" do
      expect(described_class.new({ "id" => "x" }, client: client).full_set).to be_nil
    end

    it "raises when the card is not attached to a client" do
      expect { card.full_set }.to raise_error(TCGdex::Error, /not attached to a TCGdex client/)
    end
  end
end
