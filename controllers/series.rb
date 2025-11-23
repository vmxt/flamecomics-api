# frozen_string_literal: true

require 'httparty'
require 'nokogiri'
require 'uri'
require 'cgi'
require 'time'
require_relative '../utils/variables'
require_relative '../utils/image_helper'
require_relative '../utils/time_helper'

class SeriesController
  extend ImageHelper

  def self.fetch_details(id)
    url = "#{Variables::ORIGIN}/series/#{id}"
    response = HTTParty.get(url)
    raise "Failed to fetch details: Status #{response.code}" unless response.code == 200

    doc = Nokogiri::HTML(response.body)

    title = doc.at_css('h1.mantine-Title-root')&.text&.strip || 'Unknown'
    alt_titles = doc.at_css('.SeriesPage_altTitles__OoTLD')&.text&.strip || 'Unknown'
    status = doc.css('.mantine-Badge-root').find do |b|
      b.text.match?(/Ongoing|Dropped|Completed/i)
    end&.text&.strip || 'Unknown'
    genres = doc.css('.SeriesPage_badge__K0nlO span.mantine-Badge-label').map { |g| g.text.strip }

    synopsis_node = doc.at_css('.mantine-focus-auto.SeriesPage_descriptionWrapper__Ta-fO.m_b6d8b162.mantine-Text-root')

    synopsis = if synopsis_node
                 raw_html = synopsis_node.inner_html.to_s
                 decoded_html = CGI.unescapeHTML(raw_html)
                 fragment = Nokogiri::HTML.fragment(decoded_html)
                 fragment.text.strip
               else
                 'Unknown'
               end

    info = {}
    doc.css('div.ProductionInfoList_paper__lHdlu').each do |div|
      key = div.at_css('p[class*="infoField"]')&.text&.strip
      val = div.at_css('p[class*="infoValue"]')&.text&.strip
      info[key] = val if key && val
    end

    img_src = doc.at_css('img.SeriesPage_cover__cEjW-')&.[]('src') ||
              doc.at_css('img[data-nimg="1"]')&.[]('src') ||
              doc.at_css('img[data-role="cover"]')&.[]('src')
    poster_src = normalize_image_url(img_src)

    chapters = doc.css('a.ChapterCard_chapterWrapper__NIPp5').map do |ch|
      href = ch['href']
      chapter_id = href&.sub(%r{^/series/#{id}/}, '')
      thumb_el = ch.at_css('.ChapterCard_chapterThumbnail__oBFim img')
      thumb = thumb_el&.[]('src')
      img_url = normalize_image_url(thumb)
      raw_date = ch.at_css('p[data-size="xs"]')&.[]('title')
      time_obj = raw_date ? Time.parse(raw_date) : nil
      date = TimeHelper.time_ago_in_words(time_obj)
      {
        chapter_id: chapter_id,
        img_url: img_url,
        label: ch.at_css('p[data-size="md"]')&.text&.strip || 'Unknown',
        date: date
      }
    end

    {
      title: title,
      alternative_titles: alt_titles,
      poster_src: poster_src,
      genres: genres,
      type: info['Type'] || 'Unknown',
      status: status,
      author: info['Author'] || 'Unknown',
      artist: info['Artist'] || 'Unknown',
      serialization: info['Publisher'] || 'Unknown',
      release_year: info['Release Year'] || 'Unknown',
      language: info['Language'] || 'Unknown',
      synopsis: synopsis,
      chapters_length: chapters.size,
      chapters: chapters
    }
  rescue StandardError => e
    { error: "Error fetching details: #{e.message}" }
  end

  private_class_method def self.extract_thumbnail(thumb_el)
    return unless thumb_el

    img_src = thumb_el.at_css('img')&.[]('src')
    return img_src if img_src

    style = thumb_el['style']
    match = style&.match(/url\(['"]?(.*?)['"]?\)/)
    match&.captures&.first
  end
end
