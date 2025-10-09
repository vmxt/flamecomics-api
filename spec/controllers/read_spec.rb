# frozen_string_literal: true

require 'spec_helper'
require_relative '../../controllers/read'

RSpec.describe ReadController do
  describe '.fetch_read' do
    let(:series_id) { '1' }
    let(:chapter_id) { '2' }

    context 'when HTTP request fails' do
      it 'returns an error hash' do
        allow(HTTParty).to receive(:get).and_raise(StandardError.new("Connection refused"))

        result = described_class.fetch_read(series_id, chapter_id)
        expect(result[:error]).to match(/Connection refused/)
      end
    end

    context 'when HTTP request succeeds' do
      it 'returns parsed HTML data' do
        fake_html = <<~HTML
          <html>
            <p class="TopChapterNavbar_series_title__Jw-5V">Series Title</p>
            <p class="TopChapterNavbar_chapter_title__6pDw0">Chapter Title</p>
            <div class="m_6d731127"><img src="https://cdn.flamecomics.xyz/image1.jpg" /></div>
          </html>
        HTML
        fake_response = double('response', code: 200, body: fake_html)
        allow(HTTParty).to receive(:get).and_return(fake_response)

        result = described_class.fetch_read(series_id, chapter_id)
        expect(result[:title]).to include("Series Title")
        expect(result[:img_srcs]).to include("https://cdn.flamecomics.xyz/image1.jpg")
      end
    end
  end
end
