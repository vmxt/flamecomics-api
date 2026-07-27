# frozen_string_literal: true

require 'spec_helper'
require_relative '../../controllers/novel'

RSpec.describe NovelController do
  describe '.fetch_details' do
    let(:novel_id) { '2' }

    context 'when HTTP request fails' do
      it 'returns an error hash' do
        allow(HTTParty).to receive(:get).and_raise(StandardError.new('Timeout'))

        result = described_class.fetch_details(novel_id)

        expect(result[:error]).to match(/Timeout/)
      end
    end

    context 'when HTTP request succeeds' do
      it 'returns parsed novel details from embedded Next.js data' do
        fake_html = <<~HTML
          <html>
            <script id="__NEXT_DATA__" type="application/json">
              {
                "props": {
                  "pageProps": {
                    "novels": {
                      "novel_id": 2,
                      "title": "The Return of the Disaster-Class Hero",
                      "altTitles": ["Resurrection of The Catastrophic Hero"],
                      "description": "<p>There once was the strongest hero on Earth</p>",
                      "language": "English",
                      "type": "Web Novel",
                      "tags": ["Action", "Adventure"],
                      "author": ["SAN.G"],
                      "artist": ["Gammon"],
                      "publisher": ["Breathe"],
                      "year": 2019,
                      "status": "Dropped",
                      "cover": "thumbnail.webp",
                      "last_edit": 1762279755
                    },
                    "chapters": [
                      {
                        "chapter": "1.00",
                        "title": "",
                        "release_date": 1617556183,
                        "token": "550584af665bc8dc"
                      }
                    ]
                  }
                }
              }
            </script>
          </html>
        HTML
        allow(Time).to receive(:now).and_return(Time.at(1617566983))
        allow(HTTParty).to receive(:get).and_return(double(code: 200, body: fake_html))

        result = described_class.fetch_details(novel_id)

        expect(result).to include(
          title: 'The Return of the Disaster-Class Hero',
          alternative_titles: 'Resurrection of The Catastrophic Hero',
          poster_src: 'https://cdn.flamecomics.xyz/uploads/images/novels/2/thumbnail.webp?1762279755',
          genres: %w[Action Adventure],
          type: 'Web Novel',
          status: 'Dropped',
          author: 'SAN.G',
          artist: 'Gammon',
          serialization: 'Breathe',
          release_year: '2019',
          language: 'English',
          synopsis: 'There once was the strongest hero on Earth',
          chapters_length: 1
        )
        expect(result[:chapters].first).to include(
          chapter_id: '550584af665bc8dc',
          chapter_label: 'Chapter 1',
          img_url: nil,
          date: '3 hours ago'
        )
      end

      it 'returns normalized novel chapter fields from Mantine DOM cards' do
        fake_html = <<~HTML
          <html>
            <h1 class="mantine-Title-root">The Return of the Disaster-Class Hero</h1>
            <a class="NovelChapterCard_chapterWrapper__47ixH" href="/novel/2/550584af665bc8dc">
              <p class="NovelChapterCard_titleText__Tx3Ue" data-size="md">Chapter 1</p>
              <p data-size="xs" title="April 4, 2021 5:09 PM">5 years ago</p>
            </a>
          </html>
        HTML
        allow(Time).to receive(:now).and_return(Time.parse('April 4, 2021 8:09 PM'))
        allow(HTTParty).to receive(:get).and_return(double(code: 200, body: fake_html))

        result = described_class.fetch_details(novel_id)

        expect(result[:chapters].first).to include(
          chapter_id: '550584af665bc8dc',
          chapter_label: 'Chapter 1',
          img_url: nil,
          date: '3 hours ago'
        )
      end
    end
  end
end
