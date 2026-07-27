# frozen_string_literal: true

require 'spec_helper'
require_relative '../../controllers/novel_read'

RSpec.describe NovelReadController do
  describe '.fetch_read' do
    let(:novel_id) { '2' }
    let(:chapter_id) { '550584af665bc8dc' }

    context 'when HTTP request fails' do
      it 'returns an error hash' do
        allow(HTTParty).to receive(:get).and_raise(StandardError.new('Connection refused'))

        result = described_class.fetch_read(novel_id, chapter_id)

        expect(result[:error]).to match(/Connection refused/)
      end
    end

    context 'when HTTP request succeeds' do
      it 'returns parsed novel chapter text from embedded Next.js data' do
        fake_html = <<~HTML
          <html>
            <script id="__NEXT_DATA__" type="application/json">
              {
                "props": {
                  "pageProps": {
                    "chapter": {
                      "novel_id": 2,
                      "chapter": "1.00",
                      "chapter_title": "",
                      "content": "Translator: <strong>CrazySunbacca</strong><br/>Chapter body",
                      "token": "550584af665bc8dc",
                      "title": "The Return of the Disaster-Class Hero"
                    },
                    "previous": "previous-token",
                    "next": { "token": "next-token" }
                  }
                }
              }
            </script>
          </html>
        HTML
        allow(HTTParty).to receive(:get).and_return(double(code: 200, body: fake_html))

        result = described_class.fetch_read(novel_id, chapter_id)

        expect(result).to include(
          novel_id: '2',
          chapter_id: '550584af665bc8dc',
          next_chapter_id: 'next-token',
          prev_chapter_id: 'previous-token',
          title: 'The Return of the Disaster-Class Hero - Chapter 1',
          chapter_title: 'Chapter 1',
          content_html: 'Translator: <strong>CrazySunbacca</strong><br/>Chapter body'
        )
        expect(result[:content]).to include('Translator: CrazySunbacca', 'Chapter body')
      end

      it 'returns parsed novel chapter text from data-novel-content DOM' do
        fake_html = <<~HTML
          <html>
            <p class="TopChapterNavbar_series_title__Jw-5V">The Return of the Disaster-Class Hero</p>
            <p class="TopChapterNavbar_chapter_title__6pDw0">Chapter 1</p>
            <div data-novel-content="true">Translator: <strong>CrazySunbacca</strong><br>Chapter body</div>
          </html>
        HTML
        allow(HTTParty).to receive(:get).and_return(double(code: 200, body: fake_html))

        result = described_class.fetch_read(novel_id, chapter_id)

        expect(result).to include(
          novel_id: '2',
          chapter_id: '550584af665bc8dc',
          title: 'The Return of the Disaster-Class Hero - Chapter 1',
          chapter_title: 'Chapter 1'
        )
        expect(result[:content]).to include('Translator: CrazySunbacca', 'Chapter body')
      end
    end
  end
end
