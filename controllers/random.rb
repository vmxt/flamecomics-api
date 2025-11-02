require 'httparty'
require 'nokogiri'
require_relative '../utils/variables'

class RandomController
  def self.find_valid_id
    url = "#{Variables::ORIGIN}/browse"
    response = HTTParty.get(url)
    return nil unless response.code == 200

    doc = Nokogiri::HTML(response.body)
    ids = doc.css('a[href^="/series/"]').map do |link|
      link['href'].match(%r{/series/(\d+)})&.captures&.first
    end.compact.uniq

    return nil if ids.empty?

    ids.sample
  rescue StandardError
    nil
  end
end
