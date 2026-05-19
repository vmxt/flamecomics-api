# frozen_string_literal: true

require 'nokogiri'
require 'json'
require 'time'
require_relative '../utils/variables'
require_relative '../utils/error_response'
require_relative '../utils/http_client'
require_relative '../utils/response_cache'

class HealthController
  def self.scrapers
    response = HttpClient.get(Variables::ORIGIN)
    doc = Nokogiri::HTML(response.body.to_s)
    page_props = next_data_page_props(doc)
    latest_series = page_props&.dig('latestEntries', 'blocks').to_a.flat_map { |block| block['series'].to_a }

    {
      origin: Variables::ORIGIN,
      reachable: response.code == 200,
      status_code: response.code,
      next_data_present: !page_props.nil?,
      latest_entries_present: !latest_series.empty?,
      latest_updates_count: latest_series.size,
      latest_chapters_count: latest_series.sum { |series| series['chapters'].to_a.size },
      sample_release_date_present: sample_release_date_present?(latest_series),
      checked_at: Time.now.utc.iso8601
    }
  rescue StandardError => e
    ErrorResponse.build(e.message, code: 'scraper_health_failed', source: 'health').merge(
      origin: Variables::ORIGIN,
      reachable: false,
      checked_at: Time.now.utc.iso8601
    )
  end

  def self.cache
    {
      cache: ResponseCache.stats,
      checked_at: Time.now.utc.iso8601
    }
  end

  def self.next_data_page_props(doc)
    script = doc.at_css('script#__NEXT_DATA__')
    return unless script

    JSON.parse(script.text).dig('props', 'pageProps')
  rescue JSON::ParserError
    nil
  end
  private_class_method :next_data_page_props

  def self.sample_release_date_present?(latest_series)
    latest_series.any? do |series|
      series['chapters'].to_a.any? { |chapter| chapter['release_date'] }
    end
  end
  private_class_method :sample_release_date_present?
end
