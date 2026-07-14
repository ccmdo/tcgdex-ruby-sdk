# frozen_string_literal: true

RSpec.describe TCGdex::Http do
  subject(:http) { described_class.new(cache: nil) }

  let(:url) { "https://api.tcgdex.net/v2/en/cards/swsh3-136" }
  let(:not_found_body) { File.read(File.expand_path("../fixtures/error_404.json", __dir__)) }

  describe "#get" do
    it "returns the parsed body of a 200 response" do
      stub_request(:get, url).to_return(
        status: 200,
        body: '{"id":"swsh3-136","name":"Furret"}',
        headers: { "Content-Type" => "application/json" }
      )

      expect(http.get(url)).to eq({ "id" => "swsh3-136", "name" => "Furret" })
    end

    it "parses a top-level array body" do
      stub_request(:get, url).to_return(status: 200, body: '["Colorless","Darkness"]')

      expect(http.get(url)).to eq(%w[Colorless Darkness])
    end

    it "identifies itself with a versioned User-Agent" do
      stub_request(:get, url).to_return(status: 200, body: "{}")

      http.get(url)

      expect(a_request(:get, url)
        .with(headers: { "User-Agent" => "tcgdex-ruby-sdk/#{TCGdex::VERSION}" })).to have_been_made
    end

    it "returns nil for a missing resource" do
      stub_request(:get, url).to_return(status: 404, body: not_found_body)

      expect(http.get(url)).to be_nil
    end

    it "returns nil for other non-2xx, non-5xx responses" do
      stub_request(:get, url).to_return(status: 403, body: "")

      expect(http.get(url)).to be_nil
    end

    it "raises ServerError carrying the status and body on a 5xx" do
      stub_request(:get, url).to_return(status: 503, body: "upstream is down")

      expect { http.get(url) }.to raise_error(TCGdex::ServerError) do |error|
        expect(error.status).to eq(503)
        expect(error.body).to eq("upstream is down")
        expect(error.message).to include("503")
      end
    end

    it "raises NetworkError on timeout" do
      stub_request(:get, url).to_timeout

      expect { http.get(url) }.to raise_error(TCGdex::NetworkError, /request failed/)
    end

    it "raises NetworkError preserving the cause on a refused connection" do
      stub_request(:get, url).to_raise(Errno::ECONNREFUSED)

      expect { http.get(url) }.to raise_error(TCGdex::NetworkError) do |error|
        expect(error.cause).to be_a(Errno::ECONNREFUSED)
      end
    end

    it "raises Error when a 200 body is not valid JSON" do
      stub_request(:get, url).to_return(status: 200, body: "<html>nope</html>")

      expect { http.get(url) }.to raise_error(TCGdex::Error, /malformed JSON/)
    end
  end

  describe "caching" do
    subject(:http) { described_class.new(cache: TCGdex::Cache.new, cache_ttl: 3600) }

    before { stub_request(:get, url).to_return(status: 200, body: '{"id":"swsh3-136"}') }

    it "serves a repeated request from the cache" do
      2.times { http.get(url) }

      expect(a_request(:get, url)).to have_been_made.once
    end

    it "returns the parsed value on the cached call, not the raw body" do
      http.get(url)

      expect(http.get(url)).to eq({ "id" => "swsh3-136" })
    end

    it "refetches once the TTL has elapsed" do
      http.cache_ttl = 60
      allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC).and_return(100.0)
      http.get(url)

      allow(Process).to receive(:clock_gettime).with(Process::CLOCK_MONOTONIC).and_return(161.0)
      http.get(url)

      expect(a_request(:get, url)).to have_been_made.twice
    end

    it "does not cache missing resources" do
      stub_request(:get, url).to_return(status: 404, body: not_found_body)

      2.times { http.get(url) }

      expect(a_request(:get, url)).to have_been_made.twice
    end

    it "always refetches when the cache is disabled" do
      http.cache = nil

      2.times { http.get(url) }

      expect(a_request(:get, url)).to have_been_made.twice
    end
  end
end
