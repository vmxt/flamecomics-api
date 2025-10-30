require 'httparty'
require 'nokogiri'
require_relative '../utils/variables'
require_relative 'series'

class ReadController
  def self.fetch_read(series_id, chapter_id)
    url = "#{Variables::ORIGIN}/series/#{series_id}/#{chapter_id}"
    response = HTTParty.get(url)
    raise "Failed to fetch data: Status #{response.code}" unless response.code == 200

    doc = Nokogiri::HTML(response.body)

    series_title = doc.at_css('p.TopChapterNavbar_series_title__Jw-5V')&.text&.strip || 'Unknown Series'
    chapter_title = doc.at_css('p.TopChapterNavbar_chapter_title__6pDw0')&.text&.strip || 'Unknown Chapter'
    title = "#{series_title} - #{chapter_title}"

    img_srcs = doc.css('div.m_6d731127 img').filter_map do |img|
      style = img['style'] || ''
      next if style.include?('display:none')

      src = img['src'] || img['data-src']
      next if src.to_s.empty?
      next if src.include?('read_on_flame') || src.include?('commission')

      src
    end

    series_data = SeriesController.fetch_details(series_id)
    next_chapter_id = nil
    prev_chapter_id = nil

    if series_data&.dig(:chapters)
      chapters = series_data[:chapters]
      idx = chapters.find_index { |c| c[:chapter_id] == chapter_id }

      if idx
        next_chapter_id = chapters[idx - 1][:chapter_id] if idx.positive?
        prev_chapter_id = chapters[idx + 1][:chapter_id] if idx < chapters.size - 1
      end
    end

    {
      series_id: series_id,
      chapter_id: chapter_id,
      next_chapter_id: next_chapter_id,
      prev_chapter_id: prev_chapter_id,
      title: title,
      count: img_srcs.size,
      img_srcs: img_srcs
    }
  rescue StandardError => e
    { error: "Error fetching data: #{e.message}" }
  end
end
