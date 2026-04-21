# frozen_string_literal: true

require 'httparty'
require 'nokogiri'
require 'cgi'
require 'uri'
require_relative '../utils/variables'
require_relative '../utils/image_helper'

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
      latest_updates: extract_latest_updates(doc),
      novels: extract_novels(doc)
    }
  rescue StandardError => e
    { error: "Error fetching data: #{e.message}" }
  end

  private

  def extract_spotlight(doc)
    doc.css('div[data-orientation="horizontal"]').filter_map do |slide|
      link = slide.at_css('a[href^="/series/"]')
      id = link&.[]('href')&.split('/')&.last
      next unless id

      title = slide.at_css('h2, h3')&.text&.strip
      next if title.to_s.empty?

      img_url = normalize_image_url(slide.at_css('img')&.[]('src'))
      next unless img_url

      genres = slide.css('a[href^="/genre/"] span')
                    .map { |x| x.text.strip }
                    .reject(&:empty?)
                    .uniq

      { id: id, title: title, img_url: img_url, genres: genres }
    end
  end

  def extract_cards(doc, selector)
    section = doc.at_css(selector)
    return [] unless section

    section.css('.m_96bdd299.mantine-Grid-col').filter_map do |elem|
      link = elem.at_css('a[href^="/series/"]')
      next unless link

      id = link['href']&.split('/')&.last
      title = elem.at_css('h3 span')&.text&.strip

      img_url = normalize_image_url(elem.at_css('img')&.[]('src'))
      next unless id && title && img_url

      language = elem.at_css('[data-nosnippet] span')&.text&.strip
      language = nil if language&.empty?

      likes = parse_likes(elem.at_css('svg + span')&.text)

      {
        id: id,
        title: title,
        img_url: img_url,
        language: language,
        likes: likes
      }
    end
  end

  def extract_latest_updates(doc)
    doc.css('.m_96bdd299.mantine-Grid-col').filter_map do |elem|
      title_a = elem.at_css('a.mantine-Text-root[data-size="md"]')
      id = title_a&.[]('href')&.split('/')&.last
      title = title_a&.text&.strip
      next unless id && title

      img_url = normalize_image_url(elem.at_css('img')&.[]('src'))
      next unless img_url

      language = elem.at_css('[data-nosnippet] span')&.text&.strip
      language = nil if language&.empty?

      chapters = elem.css('a[href^="/series/"]').select do |a|
        a['href'].split('/').length >= 4
      end.map do |link|
        {
          chapter_id: link['href'].split('/').last,
          chapter_title: link.at_css('p')&.text&.strip,
          chapter_date: nil
        }
      end

      next if chapters.empty?

      {
        id: id,
        title: title,
        img_url: img_url,
        language: language,
        chapters: chapters
      }
    end
  end

  def extract_novels(doc)
    section = doc.at_css('#novels')
    return [] unless section

    section.css('.m_96bdd299.mantine-Grid-col').filter_map do |elem|
      link = elem.at_css('a[href^="/novel/"]')
      next unless link

      id = link['href']&.split('/')&.last
      title = elem.at_css('h3 span')&.text&.strip

      img_url = normalize_image_url(elem.at_css('img')&.[]('src'))
      next unless id && title && img_url

      language = elem.at_css('[data-nosnippet] span')&.text&.strip
      language = nil if language&.empty?

      likes = parse_likes(elem.at_css('svg + span')&.text)
      status = elem.css('.mantine-Badge-label').last&.text&.strip

      {
        id: id,
        title: title,
        img_url: img_url,
        language: language,
        likes: likes,
        status: status
      }
    end
  end

  def parse_likes(text)
    return unless text

    text.include?('K') ? (text.delete('K').to_f * 1000).to_i : text.gsub(/[^\d]/, '').to_i
  end

  def normalize_image_url(url)
    return unless url

    if url.include?('/_next/image')
      decoded = CGI.unescape(url)
      match = decoded.match(%r{url=(https?://[^&]+)})
      return match[1] if match
    end

    url.start_with?('//') ? "https:#{url}" : url
  rescue StandardError
    url
  end
end
