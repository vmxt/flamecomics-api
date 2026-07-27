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

  describe '.extract_latest_updates' do
    it 'extracts chapter dates from embedded Next.js latest entries data' do
      allow(Time).to receive(:now).and_return(Time.at(1_700_010_800))

      fixture = File.read(File.expand_path('../fixtures/home_next_data.html', __dir__))
      doc = Nokogiri::HTML(fixture)

      result = described_class.send(:extract_latest_updates, doc)

      expect(result.first[:img_url]).to eq('https://cdn.flamecomics.xyz/uploads/images/series/127/thumbnail.webp?1700000123')
      expect(result.first).to include(
        id: '127',
        title: 'Sample Series',
        chapter_id: 'chapter-token',
        chapter_title: 'Chapter 136',
        chapter_date: '3 hours ago'
      )
      expect(result.last).to include(
        chapter_id: 'chapter-token-2',
        chapter_title: 'Chapter 135 - A Real Chapter Title'
      )
    end

    it 'extracts the chapter date from dynamic SeriesCard date classes' do
      doc = Nokogiri::HTML(<<~HTML)
        <div class="m_96bdd299 mantine-Grid-col">
          <a class="mantine-Text-root" data-size="md" href="/series/sample-series">Sample Series</a>
          <img src="https://example.com/cover.jpg">
          <div>
            <a href="/series/sample-series/chapter-1">
              <p>Chapter 1</p>
            </a>
            <p class="mantine-focus-auto SeriesCard_date__ZX42d m_b6d8b162 mantine-Text-root"
               data-size="xs"
               data-line-clamp="true">3 hours ago</p>
          </div>
        </div>
      HTML

      result = described_class.send(:extract_latest_updates, doc)

      expect(result.first).to include(
        id: 'sample-series',
        title: 'Sample Series',
        chapter_id: 'chapter-1',
        chapter_title: 'Chapter 1',
        chapter_date: '3 hours ago'
      )
    end
  end

  describe '.extract_spotlight' do
    it 'extracts spotlight entries from embedded carousel data without duplicates' do
      fixture = File.read(File.expand_path('../fixtures/home_next_data.html', __dir__))
      doc = Nokogiri::HTML(fixture)

      result = described_class.send(:extract_spotlight, doc)

      expect(result.map { |item| item[:id] }).to eq(%w[2 1])
      expect(result.first).to include(
        title: "Omniscient Reader's Viewpoint",
        img_url: 'https://cdn.flamecomics.xyz/uploads/images/carousel/carousel-1762513823920.webp',
        genres: %w[Action Adventure Fantasy Survival]
      )
    end

    it 'deduplicates DOM spotlight entries by series id' do
      doc = Nokogiri::HTML(<<~HTML)
        <div data-orientation="horizontal">
          <a href="/series/2"><h2>Omniscient Reader's Viewpoint</h2></a>
          <img src="https://example.com/orv.webp">
          <a href="/genre/action"><span>Action</span></a>
        </div>
        <div data-orientation="horizontal">
          <a href="/series/2"><h2>Omniscient Reader's Viewpoint</h2></a>
          <img src="https://example.com/orv.webp">
          <a href="/genre/action"><span>Action</span></a>
        </div>
      HTML

      result = described_class.send(:extract_spotlight, doc)

      expect(result.size).to eq(1)
      expect(result.first[:id]).to eq('2')
    end
  end

  describe '.extract_novels' do
    let(:novels_next_data_html) do
      <<~HTML
        <script id="__NEXT_DATA__" type="application/json">
          {
            "props": {
              "pageProps": {
                "latestNovels": {
                  "blocks": [
                    {
                      "title": "Latest Novels",
                      "series": [
                        {
                          "novel_id": 5,
                          "title": "Damn Reincarnation",
                          "likes": 16,
                          "status": "Dropped",
                          "cover": "thumbnail.webp",
                          "country": "KR",
                          "last_edit": 1762279468
                        }
                      ]
                    }
                  ]
                }
              }
            }
          }
        </script>
      HTML
    end

    let(:novel_cards_html) do
      <<~HTML
        <section>
          <h2 class="mantine-Title-root">Latest Novels</h2>
          <div class="m_410352e9 mantine-Grid-root">
            <div class="m_96bdd299 mantine-Grid-col __m__-Rdmmap6n6">
              <div class="SeriesCard_chapterCardContainer__8ik-p">
                <a class="SeriesCard_chapterImageLink__4Vt3E" title="Damn Reincarnation" href="/novel/5">
                  <img alt="Damn Reincarnation"
                       src="/_next/image?url=https%3A%2F%2Fcdn.flamecomics.xyz%2Fuploads%2Fimages%2Fnovels%2F5%2Fthumbnail.webp%3F1762279468&amp;w=1920&amp;q=75">
                  <div class="mantine-Badge-root" data-nosnippet="true">
                    <span class="mantine-Badge-label">KR</span>
                  </div>
                </a>
                <h3 class="mantine-Title-root" data-order="3">
                  <a class="mantine-focus-auto mantine-Text-root"
                     data-size="md"
                     href="/novel/5">Damn Reincarnation</a>
                </h3>
                <svg class="bi bi-heart-fill"></svg><span style="font-size:11px">16</span>
                <div class="mantine-Badge-root" data-variant="outline" data-size="xs">
                  <span class="mantine-Badge-label">Dropped</span>
                </div>
              </div>
            </div>
          </div>
        </section>
      HTML
    end

    let(:expected_novel) do
      {
        id: '5',
        title: 'Damn Reincarnation',
        img_url: 'https://cdn.flamecomics.xyz/uploads/images/novels/5/thumbnail.webp?1762279468',
        language: 'KR',
        likes: 16,
        status: 'Dropped'
      }
    end

    it 'extracts novel cards from embedded Next.js latest novels data' do
      doc = Nokogiri::HTML(novels_next_data_html)

      result = described_class.send(:extract_novels, doc)

      expect(result.first).to include(expected_novel)
    end

    it 'extracts novel cards when titles are rendered as Mantine text anchors' do
      doc = Nokogiri::HTML(novel_cards_html)

      result = described_class.send(:extract_novels, doc)

      expect(result.first).to include(expected_novel)
    end
  end
end
