# frozen_string_literal: true

# Opt-in check against the real API, no cassette. Run it explicitly:
#   LIVE=1 bundle exec rspec spec/integration/live_smoke_spec.rb
RSpec.describe "live API smoke", if: ENV["LIVE"] == "1" do
  around do |example|
    VCR.turned_off do
      WebMock.allow_net_connect!
      example.run
    ensure
      WebMock.disable_net_connect!(allow_localhost: false)
    end
  end

  it "fetches Furret for real" do
    expect(TCGdex.new.card.get("swsh3-136").name).to eq("Furret")
  end

  it "lists types for real" do
    expect(TCGdex.new.type.list).to include("Colorless")
  end
end
