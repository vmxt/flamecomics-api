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
    alt_titles = doc.at_css('.SeriesPage_altTitles__UI8Ij')&.text&.strip || 'Unknown'
    status = doc.css('.mantine-Badge-root').find do |b|
      b.text.match?(/Ongoing|Dropped|Completed/i)
    end&.text&.strip || 'Unknown'
    genres = doc.css('.SeriesPage_badge__ZSRhM span.mantine-Badge-label').map { |g| g.text.strip }

    raw_synopsis = doc.css('div.SeriesPage_paper__mf3li p.mantine-Text-root').find do |p|
      p.inner_html.include?('&lt;p&gt;')
    end&.inner_html || ''
    synopsis = begin
      Nokogiri::HTML.fragment(raw_synopsis.gsub('&lt;', '<').gsub('&gt;', '>')).text.strip
    rescue StandardError
      'Unknown'
    end

    info = doc.css('div.SeriesPage_paper__mf3li').each_with_object({}) do |div, h|
      key = div.at_css('p.SeriesPage_infoField__KolqF')&.text&.strip
      val = div.at_css('p.SeriesPage_infoValue__kbVfH')&.text&.strip
      h[key] = val if key && val
    end

    img_src = doc.at_css('img.SeriesPage_cover__j6TrW')&.[]('src') ||
              doc.at_css('img[data-role="cover"]')&.[]('src') ||
              doc.at_css('img.mantine-Image-image')&.[]('src')
    poster_src = normalize_image_url(img_src)

    chapters = doc.css('a.ChapterCard_chapterWrapper__YjOzx').map do |ch|
      href = ch['href']
      chapter_id = href&.sub(%r{^/series/#{id}/}, '')
      thumb_el = ch.at_css('.ChapterCard_chapterThumbnail__bik6B') || ch.at_css('.mantine-Image-root') || ch.at_css('img')
      thumb = extract_thumbnail(thumb_el)
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
    return unless style

    match = style.match(/url\(['"]?(.*?)['"]?\)/)
    match&.captures&.first
  end
end
