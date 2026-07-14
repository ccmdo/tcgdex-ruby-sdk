# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.default_cassette_options = { record: :once, match_requests_on: %i[method uri] }
  # Opt in per example with `it "...", :vcr do`; the cassette is named after the example.
  config.configure_rspec_metadata!
end
