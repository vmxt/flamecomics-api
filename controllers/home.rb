require 'httparty'
require 'nokogiri'
require 'cgi'
require 'uri'
require_relative '../utils/variables'

module Home
  extend self

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
  rescue => e
    { error: "Error fetching data: #{e.message}" }
  end

  private

  def extract_spotlight(doc)
    doc.css('.mantine-Carousel-slide').filter_map do |elem|
      title = elem.css('h3.Carousel_infoTitle__9V64e, h2.Carousel_infoTitle__9V64e').text.strip
      link = elem.at_css('a[href^="/series/"]')
      id = link&.[]('href')&.split('/')&.last
      img_url = parse_image(elem.at_css('img')&.[]('src'))
      genres = elem.css('.mantine-Badge-root a').map(&:text).map(&:strip).reject(&:empty?)
      next if title.empty? || id.nil? || img_url.nil? || genres.empty?
      { id:, title:, img_url:, genres: }
    end
  end

  def extract_cards(doc, selector)
    section = doc.at_css(selector)
    return [] unless section

    section.css('.mantine-Grid-col').filter_map do |elem|
      link = elem.at_css('a[href^="/series/"]')
      next unless link

      id = link['href'].split('/').last
      title = elem.at_css('p.mantine-Text-root')&.text&.strip
      img_url = parse_image(elem.at_css('img')&.[]('src'))
      next unless id && title && img_url

      status = elem.at_css('.mantine-Badge-label')&.text&.strip
      likes_text = elem.at_css('svg.bi-heart-fill')&.parent&.text&.strip
      likes = parse_likes(likes_text)
      { id:, title:, img_url:, status:, likes: }
    end
  end

  def extract_latest_updates(doc)
    doc.css('.m_96bdd299.mantine-Grid-col').filter_map do |elem|
      title_a = elem.at_css('a.mantine-Text-root[data-size="md"]')
      title = title_a&.text&.strip
      id = title_a&.[]('href')&.split('/')&.last
      next unless id && title

      img_url = parse_image(elem.at_css('img')&.[]('src'))
      chapters = elem.css("a[href*=\"/series/#{id}/\"]").filter_map do |link|
        ch_title = link.at_css('p')&.text&.strip
        ch_id = link['href'].split('/').last
        ch_date = link.at_css('p.SeriesCard_date__wbLsz')&.text&.strip
        next unless ch_title && ch_id && ch_date
        { chapter_id: ch_id, chapter_title: ch_title, chapter_date: ch_date }
      end
      next if chapters.empty? || img_url.nil?
      { id:, title:, img_url:, status: elem.at_css('.mantine-Badge-label')&.text&.strip, chapters: }
    end
  end

  def parse_image(src)
    return unless src
    uri = URI.parse(src) rescue nil
    return unless uri
    query = URI.decode_www_form(uri.query || '').to_h
    query['url'] ? CGI.unescape(query['url']) :
      (src.start_with?('/') ? URI.join('https://cdn.flamecomics.xyz', src).to_s : src)
  end

  def parse_likes(text)
    return unless text
    text.include?('K') ? (text.delete('K').to_f * 1000).to_i : text.gsub(/[^\d]/, '').to_i
  end
end
