require 'spec_helper'
require_relative '../../controllers/browse'

RSpec.describe BrowseController do
  describe '.fetch_series' do
    it 'returns error when HTTP request fails' do
      mock_response = double(code: 500, body: '')
      allow(HTTParty).to receive(:get).and_return(mock_response)

      result = described_class.fetch_series
      expect(result[:error]).to match(/Failed to fetch data/)
    end

    it 'returns parsed data when request is successful' do
      html = <<~HTML
        <div class="mantine-Group-root">
          <div class="DescSeriesCard_imageOuter__jCi_p">
            <img src="/_next/image?url=https%3A%2F%2Fcdn.flamecomics.xyz%2Fimg.jpg"/>
          </div>
          <div class="mantine-Stack-root">
            <a href="/series/123">Sample Series</a>
            <span class="bi-heart-fill"></span><span>123</span>
            <span class="mantine-Badge-label">Ongoing</span>
            <div class="DescSeriesCard_description__XNkvv"><p>Nice comic</p></div>
          </div>
        </div>
      HTML

      mock_response = double(code: 200, body: html)
      allow(HTTParty).to receive(:get).and_return(mock_response)

      result = described_class.fetch_series
      expect(result[:count]).to eq(1)
      expect(result[:comics].first[:title]).to eq('Sample Series')
    end
  end
end
