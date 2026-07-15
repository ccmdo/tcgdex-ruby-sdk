# frozen_string_literal: true

RSpec.describe TCGdex::VariantDetailed do
  it "reads the printing description, camelCase keys mapped" do
    variant = described_class.new(
      { "type" => "reverse", "size" => "standard", "variantId" => "cm4kqul3x1bwlz1f",
        "subType" => "pokeball", "stamp" => ["staff"], "foil" => "cosmos" }
    )

    expect(variant).to have_attributes(
      type: "reverse", size: "standard", variant_id: "cm4kqul3x1bwlz1f",
      sub_type: "pokeball", stamp: ["staff"], foil: "cosmos"
    )
  end

  it "casts its own pricing" do
    variant = described_class.new(
      { "type" => "normal", "pricing" => { "cardmarket" => { "trend" => 0.1 } } }
    )

    expect(variant.pricing).to be_a(TCGdex::Pricing)
    expect(variant.pricing.cardmarket.trend).to eq(0.1)
  end

  it "reads nil for the fields plain printings do not carry" do
    variant = described_class.new({ "type" => "normal", "size" => "standard" })

    expect(variant).to have_attributes(sub_type: nil, stamp: nil, foil: nil, pricing: nil)
  end
end
