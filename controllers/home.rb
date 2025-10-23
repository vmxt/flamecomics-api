require 'httparty'
require 'nokogiri'
require 'cgi'
require 'uri'
require 'time'
require_relative '../utils/variables'
require_relative '../utils/image_helper'
require_relative '../utils/time_helper'

module Home
  extend self
  include ImageHelper

  def fetch_data
    url = Variables::ORIGIN
    response = HTTParty.get(url)
    raise "Failed to fetch data: HTTP #{response.code}" unless response.code == 200

    doc = Nokogiri::HTML(response.body)

    {
      spotlight: extract_spotlight(doc),
      popular: extract_cards(doc, '#popular'),
      staff_picks: extract_cards(doc, '#staff-picks'),
      latest_updates: extract_latest_updates(doc)
    }
  rescue StandardError => e
    { error: "Error fetching data: #{e.message}" }
  end

  private

  def extract_spotlight(doc)
    doc.css('.mantine-Carousel-slide').filter_map do |elem|
      title = elem.css('h3.Carousel_infoTitle__9V64e, h2.Carousel_infoTitle__9V64e').text.strip
      link = elem.at_css('a[href^="/series/"]')
      href = link&.[]('href')
      id = href&.split('/')&.last
      img_url = normalize_image_url(elem.at_css('img')&.[]('src'))
      genres = elem.css('.mantine-Badge-root a').map { |x| x.text.strip }.reject(&:empty?)
      next if title.empty? || id.nil? || img_url.nil? || genres.empty?

      { id: id, title: title, img_url: img_url, genres: genres }
    end
  end

  def extract_cards(doc, selector)
    section = doc.at_css(selector)
    return [] unless section

    section.css('.mantine-Grid-col').filter_map do |elem|
      link = elem.at_css('a[href^="/series/"]')
      next unless link

      href = link['href']
      id = href&.split('/')&.last
      title = elem.at_css('p.mantine-Text-root')&.text&.strip
      img_url = normalize_image_url(elem.at_css('img')&.[]('src'))
      next unless id && title && img_url

      status = elem.at_css('.mantine-Badge-label')&.text&.strip
      likes_el = elem.at_css('svg.bi-heart-fill')
      likes_text = likes_el ? likes_el.parent&.text&.strip : nil
      likes = parse_likes(likes_text)

      { id: id, title: title, img_url: img_url, status: status, likes: likes }
    end
  end

  def extract_latest_updates(doc)
    doc.css('.m_96bdd299.mantine-Grid-col').filter_map do |elem|
      title_a = elem.at_css('a.mantine-Text-root[data-size="md"]')
      href = title_a&.[]('href')
      id = href&.split('/')&.last
      title = title_a&.text&.strip
      next unless id && title

      img_url = normalize_image_url(elem.at_css('img')&.[]('src'))
      next unless img_url

      chapters = elem.css("a[href*=\"/series/#{id}/\"]").filter_map do |link|
        ch_title = link.at_css('p')&.text&.strip
        ch_href = link['href']
        ch_id = ch_href&.split('/')&.last

        raw_date = link.at_css('p.SeriesCard_date__wbLsz')&.[]('title') ||
                   link.at_css('p[data-size="xs"]')&.[]('title') ||
                   link.at_css('p.SeriesCard_date__wbLsz')&.text ||
                   link.at_css('p[data-size="xs"]')&.text

        ch_date = if raw_date
                    begin
                      time_obj = Time.parse(raw_date)
                      TimeHelper.time_ago_in_words(time_obj)
                    rescue ArgumentError
                      raw_date.strip
                    end
                  else
                    'Unknown'
                  end

        next unless ch_title && ch_id && ch_date

        { chapter_id: ch_id, chapter_title: ch_title, chapter_date: ch_date }
      end

      next if chapters.empty?

      {
        id: id,
        title: title,
        img_url: img_url,
        status: elem.at_css('.mantine-Badge-label')&.text&.strip,
        chapters: chapters
      }
    end
  end

  def parse_likes(text)
    return unless text

    text.include?('K') ? (text.delete('K').to_f * 1000).to_i : text.gsub(/[^\d]/, '').to_i
  end
end
