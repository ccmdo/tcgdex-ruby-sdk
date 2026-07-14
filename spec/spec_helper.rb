# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "tcgdex"
require "webmock/rspec"

WebMock.disable_net_connect!(allow_localhost: false)

# Static API samples captured from the live API, shared by every spec.
module Fixtures
  FIXTURES_DIR = File.expand_path("fixtures", __dir__)

  # @return [String] the raw JSON
  def fixture(name)
    File.read(File.join(FIXTURES_DIR, "#{name}.json"))
  end

  # @return [Hash, Array] the parsed JSON
  def parsed_fixture(name)
    JSON.parse(fixture(name))
  end
end

RSpec.configure do |config|
  config.include Fixtures

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.warnings = false
  config.order = :random
  Kernel.srand config.seed
end
