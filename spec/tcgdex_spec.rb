# frozen_string_literal: true

RSpec.describe TCGdex do
  it "has a semver version number" do
    expect(TCGdex::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
  end
end
