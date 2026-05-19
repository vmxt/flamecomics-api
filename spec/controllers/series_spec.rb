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

      it 'returns normalized chapter fields' do
        fake_html = <<~HTML
          <html>
            <h1 class="mantine-Title-root">Mock Series</h1>
            <a class="ChapterCard_chapterWrapper__NIPp5" href="/series/123/chapter-token">
              <div class="ChapterCard_chapterThumbnail__oBFim">
                <img src="https://example.com/chapter.jpg">
              </div>
              <p data-size="md">Chapter 12 - The Test Title</p>
              <p data-size="xs" title="2023-11-14T22:13:20Z"></p>
            </a>
          </html>
        HTML
        fake_response = double('response', code: 200, body: fake_html)
        allow(HTTParty).to receive(:get).and_return(fake_response)
        allow(Time).to receive(:now).and_return(Time.utc(2023, 11, 15, 1, 13, 20))

        result = described_class.fetch_details(series_id)

        expect(result[:chapters].first).to include(
          chapter_id: 'chapter-token',
          chapter_number: '12',
          chapter_title: 'The Test Title',
          chapter_label: 'Chapter 12 - The Test Title',
          chapter_date: '3 hours ago',
          label: 'Chapter 12 - The Test Title',
          date: '3 hours ago'
        )
      end
    end
  end
end
