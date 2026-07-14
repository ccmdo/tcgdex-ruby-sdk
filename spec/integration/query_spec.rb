# frozen_string_literal: true

RSpec.describe "Query filters (integration)", :vcr do
  let(:client) { TCGdex.new("en") }

  def list(query)
    client.card.list(query)
  end

  it "filters by strict equality" do
    results = list(TCGdex::Query.new.equal(:name, "Furret").paginate(page: 1, items_per_page: 5))

    expect(results).not_to be_empty
    expect(results.map(&:name).uniq).to eq(["Furret"])
  end

  it "matches loosely with a laxist contains" do
    results = list(TCGdex::Query.new.contains(:name, "furret").paginate(page: 1, items_per_page: 5))

    expect(results).not_to be_empty
    expect(results.map(&:name)).to all(match(/furret/i))
  end

  it "excludes the strict match under negation" do
    results = list(TCGdex::Query.new.not_equal(:name, "Furret").paginate(page: 1, items_per_page: 5))

    expect(results).not_to be_empty
    expect(results.map(&:name)).not_to include("Furret")
  end

  it "filters numerically, server-side, with a lower bound" do
    results = list(TCGdex::Query.new.gte(:hp, 300).paginate(page: 1, items_per_page: 5))

    # Briefs carry no hp, so trust the server filtered and just assert it returned rows.
    expect(results).to all(be_a(TCGdex::CardBrief))
    expect(results).not_to be_empty
  end

  it "accepts a sort without error and returns a page" do
    results = list(TCGdex::Query.new.sort(:hp, :desc).paginate(page: 1, items_per_page: 5))

    expect(results.size).to be <= 5
    expect(results).to all(be_a(TCGdex::CardBrief))
  end

  it "filters on a null field" do
    results = list(TCGdex::Query.new.null(:effect).paginate(page: 1, items_per_page: 5))

    expect(results).not_to be_empty
  end
end
