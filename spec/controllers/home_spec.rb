# frozen_string_literal: true

require 'spec_helper'
require_relative '../../controllers/home'

RSpec.describe Home do
  describe '.fetch_data' do
    let(:html_response) do
      <<-HTML
        <html>
          <body>
            <div class="mantine-Title-root" data-order="2">Spotlight</div>
            <div class="mantine-Title-root" data-order="2">Popular</div>
            <div class="mantine-Title-root" data-order="2">Staff Picks</div>
            <div class="mantine-Title-root" data-order="2">Latest Updates</div>
          </body>
        </html>
      HTML
    end

    context 'when HTTP request fails' do
      it 'returns an error hash' do
        allow(HTTParty).to receive(:get).and_return(double(code: 500))
        result = Home.fetch_data
        expect(result).to be_a(Hash)
        expect(result).to have_key(:error)
      end
    end

    context 'when HTTP request succeeds' do
      it 'returns parsed HTML data' do
        allow(HTTParty).to receive(:get).and_return(double(code: 200, body: html_response))
        result = Home.fetch_data

        expect(result).to be_a(Hash)
        expect(result.keys).to include(:spotlight, :popular, :staff_picks, :latest_updates)

        expect(result[:spotlight]).to be_a(Array)
        expect(result[:popular]).to be_a(Array)
        expect(result[:staff_picks]).to be_a(Array)
        expect(result[:latest_updates]).to be_a(Array)
      end
    end
  end
end
