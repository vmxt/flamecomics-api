# frozen_string_literal: true

require 'spec_helper'
require_relative '../../controllers/home'

RSpec.describe Home do
  describe '.fetch_data' do
    context 'when HTTP request fails' do
      it 'returns an error hash' do
        allow(HTTParty).to receive(:get).and_raise(StandardError.new("Network error"))

        result = Home.fetch_data
        expect(result[:error] || result["error"]).to match(/Network error/)
      end
    end

    context 'when HTTP request succeeds' do
      it 'returns parsed HTML data' do
        fake_html = '<html><body><div id="Popular"></div></body></html>'
        fake_response = double('response', code: 200, body: fake_html)
        allow(HTTParty).to receive(:get).and_return(fake_response)

        result = Home.fetch_data
        expect(result).to be_a(Hash)
        expect(result.keys).to include('spotlight', 'popular', 'latest_updates')
      end
    end
  end
end
