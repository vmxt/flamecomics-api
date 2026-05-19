# frozen_string_literal: true

require 'nokogiri'
require_relative '../utils/variables'
require_relative '../utils/image_helper'
require_relative '../utils/chapter_label_formatter'
require_relative '../utils/error_response'
require_relative '../utils/http_client'
require_relative '../utils/home_card_extractor'
require_relative '../utils/home_chapter_date_extractor'
require_relative '../utils/home_latest_updates_extractor'

module Home
  extend ImageHelper
  extend ChapterLabelFormatter
  extend HomeCardExtractor
  extend HomeChapterDateExtractor
  extend HomeLatestUpdatesExtractor

  module_function

  def fetch_data
    url = Variables::ORIGIN
    response = HttpClient.get(url)
    raise "Failed to fetch data: HTTP #{response.code}" unless response.code == 200

    doc = Nokogiri::HTML(response.body)

    {
      spotlight: extract_spotlight(doc),
      popular: extract_cards(doc, '#popular'),
      staff_picks: extract_cards(doc, '#staff-picks'),
      latest_updates: extract_latest_updates(doc),
      novels: extract_novels(doc)
    }
  rescue StandardError => e
    ErrorResponse.build("Error fetching data: #{e.message}", code: 'home_fetch_failed', source: 'home')
  end
end
