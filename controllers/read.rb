require 'httparty'
require 'nokogiri'
require_relative '../utils/variables'

class ReadController
  def self.fetch_read(series_id, chapter_id)
    url = "#{Variables::ORIGIN}/series/#{series_id}/#{chapter_id}"
    response = HTTParty.get(url)
    raise "Failed to fetch data: Status #{response.code}" unless response.code == 200

    doc = Nokogiri::HTML(response.body)

    series_title  = doc.at_css('p.TopChapterNavbar_series_title__Jw-5V')&.text&.strip || 'Unknown Series'
    chapter_title = doc.at_css('p.TopChapterNavbar_chapter_title__6pDw0')&.text&.strip || 'Unknown Chapter'
    title = "#{series_title} - #{chapter_title}"

    img_srcs = doc.css('div.m_6d731127 img').filter_map do |img|
      style = img['style'] || ''
      next if style.include?('display:none')
      src = img['src'] || img['data-src']
      next unless src && !src.empty?
      next if src.include?('read_on_flame') || src.include?('commission')
      src
    end

    { series_id:, chapter_id:, title:, count: img_srcs.size, img_srcs: }
  rescue => e
    { error: "Error fetching data: #{e.message}" }
  end
end
