# frozen_string_literal: true

RSpec.describe TCGdex::BaseModel do
  # A throwaway subclass, so the DSL is tested rather than any one real model.
  before do
    stub_const("Gadget", Class.new(described_class) do
      attribute :size
    end)

    stub_const("Widget", Class.new(described_class) do
      attribute :id
      attribute :local_id
      attribute :label, key: "custom_label"
      attribute :gadget, model: Gadget
      attribute :gadgets, model: Gadget, array: true
    end)
  end

  describe ".attribute" do
    it "reads a plain key" do
      expect(Widget.new({ "id" => "swsh3-136" }).id).to eq("swsh3-136")
    end

    it "camelizes a multi-word name into its JSON key" do
      expect(Widget.new({ "localId" => "136" }).local_id).to eq("136")
    end

    it "uses an explicit key when the JSON is not camelCase" do
      expect(Widget.new({ "custom_label" => "hi" }).label).to eq("hi")
    end

    it "reads nil for a key the payload omits" do
      expect(Widget.new({}).local_id).to be_nil
    end

    it "casts a nested hash into its model" do
      widget = Widget.new({ "gadget" => { "size" => 3 } })

      expect(widget.gadget).to be_a(Gadget).and have_attributes(size: 3)
    end

    it "casts each element of an array" do
      widget = Widget.new({ "gadgets" => [{ "size" => 1 }, { "size" => 2 }] })

      expect(widget.gadgets.map(&:size)).to eq([1, 2])
    end

    it "reads nil rather than raising when an array field holds something else" do
      expect(Widget.new({ "gadgets" => "unexpected" }).gadgets).to be_nil
    end

    it "inherits attributes from a parent model without polluting it" do
      sprocket = Class.new(Widget) { attribute :teeth }

      expect(sprocket.new({ "id" => "a", "teeth" => 9 }).teeth).to eq(9)
      expect(Widget.attributes).not_to have_key(:teeth)
    end
  end

  describe "unknown keys" do
    subject(:widget) { Widget.new({ "id" => "x", "pricing" => { "avg-holo" => 0.31 } }) }

    it "does not raise on a key the SDK does not model" do
      expect(widget.id).to eq("x")
    end

    it "keeps the unmodeled data reachable through to_h" do
      expect(widget.to_h["pricing"]).to eq({ "avg-holo" => 0.31 })
    end
  end

  describe "#to_h" do
    it "returns the raw parsed payload" do
      data = { "id" => "x", "gadget" => { "size" => 3 } }

      expect(Widget.new(data).to_h).to eq(data)
    end

    it "copes with a nil payload" do
      expect(Widget.new(nil).to_h).to eq({})
    end
  end

  describe "#client" do
    let(:client) { double("client") }

    it "holds the client it was built with" do
      expect(Widget.new({}, client: client).client).to be(client)
    end

    it "hands the client down to nested models, so they can lazy-load" do
      widget = Widget.new({ "gadget" => { "size" => 3 } }, client: client)

      expect(widget.gadget.client).to be(client)
    end

    it "hands the client down to models inside arrays" do
      widget = Widget.new({ "gadgets" => [{ "size" => 1 }] }, client: client)

      expect(widget.gadgets.first.client).to be(client)
    end
  end

  describe "#==" do
    it "is true for the same class carrying the same data" do
      widget = Widget.new({ "id" => "x" })
      twin = Widget.new({ "id" => "x" })

      expect(widget).to eq(twin)
    end

    it "is false for different data" do
      expect(Widget.new({ "id" => "x" })).not_to eq(Widget.new({ "id" => "y" }))
    end

    it "is false across classes, even with identical data" do
      expect(Widget.new({ "size" => 1 })).not_to eq(Gadget.new({ "size" => 1 }))
    end

    it "makes equal models interchangeable as hash keys" do
      store = { Widget.new({ "id" => "x" }) => :found }

      expect(store[Widget.new({ "id" => "x" })]).to eq(:found)
    end
  end

  describe "#inspect" do
    it "identifies the model by id rather than dumping the payload" do
      expect(Widget.new({ "id" => "swsh3-136", "gadget" => { "size" => 3 } }).inspect)
        .to eq('#<Widget "swsh3-136">')
    end

    it "falls back to the name when there is no id" do
      expect(Gadget.new({ "name" => "Furret" }).inspect).to eq('#<Gadget "Furret">')
    end

    it "says nothing more than the class when there is neither" do
      expect(Gadget.new({}).inspect).to eq("#<Gadget>")
    end
  end
end
