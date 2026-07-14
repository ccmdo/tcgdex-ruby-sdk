# frozen_string_literal: true

RSpec.describe TCGdex::Query do
  subject(:query) { described_class.new }

  describe "filters" do
    it "emits a laxist contains filter" do
      expect(query.contains(:name, "pika").to_params).to eq([["name", "pika"]])
    end

    it "passes wildcards through untouched" do
      expect(query.contains(:name, "*chu").to_params).to eq([["name", "*chu"]])
    end

    it "emits a laxist negation" do
      expect(query.not_contains(:name, "pika").to_params).to eq([["name", "not:pika"]])
    end

    it "emits strict equality" do
      expect(query.equal(:name, "Furret").to_params).to eq([["name", "eq:Furret"]])
    end

    it "emits strict negation" do
      expect(query.not_equal(:name, "Furret").to_params).to eq([["name", "neq:Furret"]])
    end

    it "emits greater than" do
      expect(query.greater_than(:hp, 50).to_params).to eq([["hp", "gt:50"]])
    end

    it "emits greater or equal" do
      expect(query.greater_or_equal(:hp, 50).to_params).to eq([["hp", "gte:50"]])
    end

    it "emits less than" do
      expect(query.less_than(:hp, 50).to_params).to eq([["hp", "lt:50"]])
    end

    it "emits less or equal" do
      expect(query.less_or_equal(:hp, 50).to_params).to eq([["hp", "lte:50"]])
    end

    it "emits null with its trailing colon" do
      expect(query.null(:effect).to_params).to eq([["effect", "null:"]])
    end

    it "emits not null with its trailing colon" do
      expect(query.not_null(:effect).to_params).to eq([["effect", "notnull:"]])
    end

    it "leaves a pipe-separated OR value intact" do
      expect(query.equal(:name, "Furret|Pikachu").to_params).to eq([["name", "eq:Furret|Pikachu"]])
    end
  end

  describe "aliases" do
    it "aliases like and includes to contains" do
      expect([described_class.instance_method(:like), described_class.instance_method(:includes)])
        .to all(eq(described_class.instance_method(:contains)))
    end

    it "aliases not_like to not_contains" do
      expect(described_class.instance_method(:not_like))
        .to eq(described_class.instance_method(:not_contains))
    end

    it "aliases the short comparison forms" do
      pairs = { eq: :equal, neq: :not_equal, gt: :greater_than,
                gte: :greater_or_equal, lt: :less_than, lte: :less_or_equal }

      short = pairs.keys.to_h { |name| [name, described_class.instance_method(name)] }
      long = pairs.to_h { |name, target| [name, described_class.instance_method(target)] }

      expect(short).to eq(long)
    end
  end

  describe "#sort" do
    it "defaults to ascending" do
      expect(query.sort(:hp).to_params).to eq([["sort:field", "hp"], ["sort:order", "ASC"]])
    end

    it "normalizes a descending symbol" do
      expect(query.sort(:hp, :desc).to_params).to eq([["sort:field", "hp"], ["sort:order", "DESC"]])
    end

    it "accepts an order given as a string" do
      expect(query.sort(:hp, "desc").to_params.last).to eq(["sort:order", "DESC"])
    end

    it "rejects an unknown order" do
      expect { query.sort(:hp, :sideways) }.to raise_error(ArgumentError, /:asc, :desc/)
    end
  end

  describe "#paginate" do
    it "defaults to 100 items per page" do
      expect(query.paginate(page: 2).to_params)
        .to eq([["pagination:page", 2], ["pagination:itemsPerPage", 100]])
    end

    it "emits the requested page size" do
      expect(query.paginate(page: 1, items_per_page: 20).to_params)
        .to eq([["pagination:page", 1], ["pagination:itemsPerPage", 20]])
    end
  end

  describe "chaining" do
    it "returns self from every builder method" do
      expect(query.contains(:name, "pika")).to be(query)
    end

    it "returns self from sort and paginate too" do
      expect(query.sort(:hp).paginate(page: 1)).to be(query)
    end

    it "keeps duplicate keys, in order, to express a range" do
      expect(query.gte(:hp, 50).lte(:hp, 90).to_params)
        .to eq([["hp", "gte:50"], ["hp", "lte:90"]])
    end

    it "accepts string keys as readily as symbols" do
      expect(query.contains("name", "pika").to_params).to eq([["name", "pika"]])
    end

    it "builds the documented full query" do
      params = query.contains(:name, "pika").gte(:hp, 60).sort(:hp, :desc)
                    .paginate(page: 1, items_per_page: 20).to_params

      expect(params).to eq(
        [["name", "pika"], ["hp", "gte:60"], ["sort:field", "hp"], ["sort:order", "DESC"],
         ["pagination:page", 1], ["pagination:itemsPerPage", 20]]
      )
    end
  end

  describe "#to_params" do
    it "does not expose the internal pairs for mutation" do
      query.contains(:name, "pika")
      query.to_params.first[1] = "mutated"

      expect(query.to_params).to eq([["name", "pika"]])
    end
  end

  describe "#to_s" do
    it "is empty for an empty query" do
      expect(query.to_s).to eq("")
    end

    it "joins pairs with & and omits the leading question mark" do
      expect(query.contains(:name, "pika").gte(:hp, 60).to_s).to eq("name=pika&hp=gte%3A60")
    end

    it "encodes the colon in an operator value" do
      expect(query.equal(:name, "Furret").to_s).to eq("name=eq%3AFurret")
    end

    it "encodes the OR pipe" do
      expect(query.equal(:name, "Furret|Pikachu").to_s).to eq("name=eq%3AFurret%7CPikachu")
    end

    it "encodes spaces" do
      expect(query.equal(:illustrator, "Tetsuya Koizumi").to_s)
        .to eq("illustrator=eq%3ATetsuya+Koizumi")
    end

    it "encodes a question mark in a value" do
      expect(query.equal(:name, "Unown ?").to_s).to eq("name=eq%3AUnown+%3F")
    end

    it "encodes non-ASCII values as UTF-8" do
      expect(query.contains(:name, "Pokémon").to_s).to eq("name=Pok%C3%A9mon")
    end

    it "encodes the colons in sort and pagination keys" do
      expect(query.sort(:hp, :desc).paginate(page: 1, items_per_page: 20).to_s)
        .to eq("sort%3Afield=hp&sort%3Aorder=DESC&pagination%3Apage=1&pagination%3AitemsPerPage=20")
    end
  end
end
