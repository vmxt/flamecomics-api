# frozen_string_literal: true

require 'spec_helper'
require_relative '../../controllers/series'

RSpec.describe SeriesController do
  describe '.fetch_details' do
    let(:series_id) { '123' }

    context 'when HTTP request fails' do
      it 'returns an error hash' do
        allow(HTTParty).to receive(:get).and_raise(StandardError.new("Timeout"))

        result = described_class.fetch_details(series_id)
        expect(result[:error]).to match(/Timeout/)
      end
    end

    context 'when HTTP request succeeds' do
      it 'returns parsed data' do
        fake_html = '<html><h1 class="mantine-Title-root">Mock Series</h1></html>'
        fake_response = double('response', code: 200, body: fake_html)
        allow(HTTParty).to receive(:get).and_return(fake_response)

        result = described_class.fetch_details(series_id)
        expect(result[:title]).to eq('Mock Series')
      end
    end
  end
end
