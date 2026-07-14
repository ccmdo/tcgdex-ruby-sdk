# frozen_string_literal: true

RSpec.describe TCGdex::Cache do
  subject(:cache) { described_class.new }

  # The cache reads the monotonic clock, never the wall clock, so time travel in
  # these specs is a matter of stubbing it.
  def freeze_clock_at(seconds)
    allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC).and_return(seconds)
  end

  describe "#set" do
    it "returns the stored value" do
      expect(cache.set("k", { "a" => 1 }, 60)).to eq({ "a" => 1 })
    end

    it "overwrites an existing entry" do
      cache.set("k", "old", 60)
      cache.set("k", "new", 60)
      expect(cache.get("k")).to eq("new")
    end
  end

  describe "#get" do
    it "returns nil for an unknown key" do
      expect(cache.get("nope")).to be_nil
    end

    it "returns the value while the entry is fresh" do
      freeze_clock_at(100.0)
      cache.set("k", "v", 60)

      freeze_clock_at(159.0)
      expect(cache.get("k")).to eq("v")
    end

    it "returns nil once the TTL has elapsed" do
      freeze_clock_at(100.0)
      cache.set("k", "v", 60)

      freeze_clock_at(161.0)
      expect(cache.get("k")).to be_nil
    end

    it "drops the expired entry rather than leaking it" do
      freeze_clock_at(100.0)
      cache.set("k", "v", 60)

      freeze_clock_at(161.0)
      cache.get("k")

      expect(cache.instance_variable_get(:@store)).to be_empty
    end

    it "stores falsey values without treating them as a miss" do
      cache.set("k", false, 60)
      expect(cache.get("k")).to be(false)
    end
  end

  describe "#clear" do
    it "drops every entry" do
      cache.set("a", 1, 60)
      cache.set("b", 2, 60)
      cache.clear

      expect([cache.get("a"), cache.get("b")]).to eq([nil, nil])
    end
  end

  describe "thread safety" do
    it "survives concurrent readers and writers" do
      threads = Array.new(8) do |i|
        Thread.new do
          200.times do |j|
            cache.set("key-#{i}-#{j % 10}", j, 60)
            cache.get("key-#{i}-#{j % 10}")
            cache.get("key-#{(i + 1) % 8}-#{j % 10}")
          end
        end
      end

      expect { threads.each(&:join) }.not_to raise_error
    end
  end
end
