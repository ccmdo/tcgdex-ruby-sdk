# frozen_string_literal: true

RSpec.describe TCGdex::Pricing do
  describe "cardmarket" do
    subject(:cardmarket) { pricing.cardmarket }

    let(:pricing) do
      described_class.new(
        { "cardmarket" => {
          "updated" => "2026-07-14T18:05:08.086Z", "unit" => "EUR", "idProduct" => 483_559,
          "avg" => 0.1, "low" => 0.02, "trend" => 0.1,
          "avg1" => 0.05, "avg7" => 0.1, "avg30" => 0.11,
          "avg-holo" => 0.31, "low-holo" => 0.04, "trend-holo" => 0.35,
          "avg1-holo" => 0.28, "avg7-holo" => 0.38, "avg30-holo" => 0.33
        } }
      )
    end

    it "reads the plain fields" do
      expect(cardmarket).to be_a(TCGdex::PricingCardmarket).and have_attributes(
        updated: "2026-07-14T18:05:08.086Z", unit: "EUR", id_product: 483_559,
        avg: 0.1, low: 0.02, trend: 0.1, avg1: 0.05, avg7: 0.1, avg30: 0.11
      )
    end

    it "maps every hyphenated holo key" do
      expect(cardmarket).to have_attributes(
        avg_holo: 0.31, low_holo: 0.04, trend_holo: 0.35,
        avg1_holo: 0.28, avg7_holo: 0.38, avg30_holo: 0.33
      )
    end

    it "leaves the other marketplace nil" do
      expect(pricing.tcgplayer).to be_nil
    end
  end

  describe "tcgplayer" do
    subject(:tcgplayer) { pricing.tcgplayer }

    let(:variant) { { "productId" => 219_333, "lowPrice" => 0.01, "marketPrice" => 0.1 } }
    let(:pricing) do
      described_class.new(
        { "tcgplayer" => {
          "updated" => "2026-07-14T18:05:05.851Z", "unit" => "USD",
          "normal" => variant, "holofoil" => variant, "reverse-holofoil" => variant,
          "1st-edition" => variant, "1st-edition-holofoil" => variant,
          "unlimited" => variant, "unlimited-holofoil" => variant
        } }
      )
    end

    it "reads the currency and timestamp" do
      expect(tcgplayer).to be_a(TCGdex::PricingTcgplayer)
        .and have_attributes(unit: "USD", updated: "2026-07-14T18:05:05.851Z")
    end

    it "casts every printing slot, hyphenated and digit-led keys included" do
      %i[normal holofoil reverse_holofoil first_edition first_edition_holofoil
         unlimited unlimited_holofoil].each do |printing|
        expect(tcgplayer.public_send(printing)).to be_a(TCGdex::PricingTcgplayerVariant)
      end
    end

    it "reads a printing's prices" do
      expect(tcgplayer.normal).to have_attributes(
        product_id: 219_333, low_price: 0.01, market_price: 0.1,
        mid_price: nil, high_price: nil, direct_low_price: nil
      )
    end
  end

  describe "tolerance" do
    it "reads all nil from an empty object" do
      pricing = described_class.new({})

      expect(pricing).to have_attributes(cardmarket: nil, tcgplayer: nil)
    end
  end
end
