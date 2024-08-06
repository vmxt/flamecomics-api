require 'httparty'
require 'nokogiri'
require_relative '../utils/get_id_from_url'
require_relative '../utils/variables'

class DetailsController
  def self.fetch_details(id)
    begin
      url = "#{Variables::ORIGIN}/series/#{id}"
      response = HTTParty.get(url)

      if response.code != 200
        raise "Status: #{response.code}"
      end

      data = response.body
      if data.nil? || data.empty?
        raise 'Data is null'
      end

      document = Nokogiri::HTML(data)

      title = document.at_css('.entry-title')&.text&.strip || 'Unknown'
      alternative_titles = document.at_css('.alternative .desktop-titles')&.text&.strip || 'Unknown'
      poster_src = document.at_css('.thumb img')&.[]('src') || 'Unknown'
      genres = document.css('.genres-container a').map(&:text).map(&:strip)
      type = document.at_css('.tsinfo .imptdt:nth-of-type(1) i')&.text&.strip || 'Unknown'
      status = document.at_css('.tsinfo .imptdt:nth-of-type(2) i')&.text&.strip || 'Unknown'
      author = document.at_css('.tsinfo .imptdt:nth-of-type(4) i')&.text&.strip || 'Unknown'
      artist = document.at_css('.tsinfo .imptdt:nth-of-type(5) i')&.text&.strip || 'Unknown'
      serialization = document.at_css('.tsinfo .imptdt:nth-of-type(6) i')&.text&.strip || 'Unknown'
      score = document.at_css('.numscore')&.text&.strip.to_f || 0.0
      synopsis = document.at_css('.summary .entry-content p:not(:empty)')&.text&.strip || 'Unknown'
      chapters = []

      document.css('.eplister ul li').each do |elem|
        chapter_id = get_id_from_url(elem.at_css('a')['href']) || 'Unknown'
        label = elem.at_css('.chapternum')&.text&.strip&.gsub("\n", ' ') || 'Unknown'
        date = elem.at_css('.chapterdate')&.text&.strip || 'Unknown'
        chapters << { id: chapter_id, label: label, date: date }
      end

      {
        title: title,
        alternativeTitles: alternative_titles,
        posterSrc: poster_src,
        genres: genres,
        type: type,
        status: status,
        author: author,
        artist: artist,
        serialization: serialization,
        score: score,
        synopsis: synopsis,
        chaptersCount: chapters.length,
        chapters: chapters
      }
    rescue StandardError => e
      { error: "Error fetching data: #{e.message}" }
    end
  end
end
