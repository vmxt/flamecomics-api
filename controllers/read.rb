require 'httparty'
require 'nokogiri'
require_relative '../utils/variables'

class ReadController
  def self.fetch_read(series_id, chapter_id)
    url      = "#{Variables::ORIGIN}/series/#{series_id}/#{chapter_id}"
    response = HTTParty.get(url)

    if response.code != 200
      raise "Failed to fetch data: Status #{response.code}"
    end

    data = response.body
    if data.nil? || data.empty?
      raise 'Received empty response data'
    end

    document = Nokogiri::HTML(data)

    series_title  = document.at_css('p.TopChapterNavbar_series_title__Jw-5V')&.text&.strip   || 'Unknown Series'
    chapter_title = document.at_css('p.TopChapterNavbar_chapter_title__6pDw0')&.text&.strip  || 'Unknown Chapter'
    title         = "#{series_title} - #{chapter_title}"

    img_srcs = []
    document.css('div.m_6d731127 img').each do |img|
      style = img['style'] || ''
      next if style.include?('display:none')

      src = img['src'] || img['data-src']
      next if src.nil? || src.empty?
      next if src.include?('read_on_flame') || src.include?('commission')

      img_srcs << src
    end

    {
      series_id:,
      chapter_id:,
      title:,
      count:  img_srcs.length,
      img_srcs:
    }

  rescue StandardError => e
    { error: "Error fetching data: #{e.message}" }
  end
end
