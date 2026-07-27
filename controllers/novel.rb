# frozen_string_literal: true

require 'json'
require 'nokogiri'
require 'time'
require_relative '../utils/variables'
require_relative '../utils/image_helper'
require_relative '../utils/time_helper'
require_relative '../utils/chapter_label_formatter'
require_relative '../utils/error_response'
require_relative '../utils/http_client'

# rubocop:disable Metrics/ClassLength

class NovelController
  extend ImageHelper
  extend ChapterLabelFormatter

  NOVEL_CHAPTER_TITLE_SELECTOR = 'p[class*="NovelChapterCard_titleText"], p[data-size="md"]'

  def self.fetch_details(id)
    url = "#{Variables::ORIGIN}/novel/#{id}"
    response = HttpClient.get(url)
    raise "Failed to fetch novel details: Status #{response.code}" unless response.code == 200

    doc = Nokogiri::HTML(response.body)

    extract_details_from_next_data(doc, id) || extract_details_from_dom(doc, id)
  rescue StandardError => e
    ErrorResponse.build("Error fetching novel details: #{e.message}", code: 'novel_fetch_failed', source: 'novel')
  end

  private_class_method def self.extract_details_from_next_data(doc, requested_id)
    page_props = next_data_page_props(doc)
    novel = page_props&.dig('novels')
    return unless novel

    chapters = page_props['chapters'].to_a
    id = novel['novel_id']&.to_s || requested_id
    normalized_chapters = chapters.filter_map { |chapter| normalized_data_chapter(chapter) }

    {
      title: present_text(novel['title']) || 'Unknown',
      alternative_titles: joined_text(novel['altTitles']) || 'Unknown',
      poster_src: novel_cover_url(novel, id),
      genres: novel['tags'].to_a,
      type: present_text(novel['type']) || 'Unknown',
      status: present_text(novel['status']) || 'Unknown',
      author: joined_text(novel['author']) || 'Unknown',
      artist: joined_text(novel['artist']) || 'Unknown',
      serialization: joined_text(novel['publisher']) || 'Unknown',
      release_year: present_text(novel['year']) || 'Unknown',
      language: present_text(novel['language']) || 'Unknown',
      synopsis: html_to_text(novel['description']) || 'Unknown',
      chapters_length: normalized_chapters.size,
      chapters: normalized_chapters
    }
  end

  private_class_method def self.extract_details_from_dom(doc, id)
    info = production_info(doc)
    chapters = doc.css('a[class*="NovelChapterCard_chapterWrapper"]').filter_map do |chapter|
      normalized_dom_chapter(chapter, id)
    end

    {
      title: doc.at_css('h1.mantine-Title-root')&.text&.strip || 'Unknown',
      alternative_titles: doc.at_css('.SeriesPage_altTitles__OoTLD')&.text&.strip || 'Unknown',
      poster_src: normalize_image_url(doc.at_css('img.SeriesPage_cover__cEjW-, img[data-nimg="1"]')&.[]('src')),
      genres: doc.css('.SeriesPage_badge__K0nlO span.mantine-Badge-label').map { |genre| genre.text.strip },
      type: info['Type'] || 'Unknown',
      status: dom_status(doc),
      author: info['Author'] || 'Unknown',
      artist: info['Artist'] || 'Unknown',
      serialization: info['Publisher'] || 'Unknown',
      release_year: info['Release Year'] || 'Unknown',
      language: info['Language'] || 'Unknown',
      synopsis: dom_synopsis(doc),
      chapters_length: chapters.size,
      chapters: chapters
    }
  end

  private_class_method def self.next_data_page_props(doc)
    script = doc.at_css('script#__NEXT_DATA__')
    return unless script

    JSON.parse(script.text).dig('props', 'pageProps')
  rescue JSON::ParserError
    nil
  end

  private_class_method def self.normalized_data_chapter(chapter)
    token = chapter['token']&.to_s
    return if token.to_s.empty?

    {
      chapter_id: token,
      chapter_label: format_chapter_label(chapter),
      img_url: nil,
      date: timestamp_date(chapter['release_date'] || chapter['public_release'])
    }
  end

  private_class_method def self.normalized_dom_chapter(chapter, novel_id)
    href = chapter['href'].to_s
    chapter_id = href.sub(%r{\A/novel/#{Regexp.escape(novel_id)}/}, '')
    return if chapter_id.empty? || chapter_id == href

    {
      chapter_id: chapter_id,
      chapter_label: chapter.at_css(NOVEL_CHAPTER_TITLE_SELECTOR)&.text&.strip || 'Unknown',
      img_url: nil,
      date: dom_chapter_date(chapter)
    }
  end

  private_class_method def self.production_info(doc)
    doc.css('div.ProductionInfoList_paper__lHdlu').each_with_object({}) do |div, info|
      key = div.at_css('p[class*="infoField"]')&.text&.strip
      value = div.at_css('p[class*="infoValue"]')&.text&.strip
      info[key] = value if key && value
    end
  end

  private_class_method def self.dom_status(doc)
    doc.css('.mantine-Badge-root').find do |badge|
      badge.text.match?(/Ongoing|Dropped|Completed|Hiatus/i)
    end&.text&.strip || 'Unknown'
  end

  private_class_method def self.dom_synopsis(doc)
    synopsis = doc.at_css('meta[name="description"]')&.[]('content') ||
               doc.at_css('meta[property="og:description"]')&.[]('content') ||
               doc.at_css('[class*="SeriesPage_descriptionWrapper"]')&.text

    clean_text(synopsis) || 'Unknown'
  end

  private_class_method def self.novel_cover_url(novel, id)
    cover = novel['cover']
    return if id.to_s.empty? || cover.to_s.empty?

    cache_buster = novel['last_edit'] || novel['time']
    url = "https://cdn.flamecomics.xyz/uploads/images/novels/#{id}/#{cover}"
    url = "#{url}?#{cache_buster}" if cache_buster

    normalize_image_url(url)
  end

  private_class_method def self.timestamp_date(timestamp)
    return unless timestamp

    TimeHelper.time_ago_in_words(Time.at(timestamp.to_i))
  end

  private_class_method def self.dom_chapter_date(chapter)
    raw_date = chapter.at_css('p[data-size="xs"]')&.[]('title')
    time_obj = raw_date ? Time.parse(raw_date) : nil

    TimeHelper.time_ago_in_words(time_obj)
  rescue ArgumentError
    nil
  end

  private_class_method def self.html_to_text(html)
    clean_text(Nokogiri::HTML.fragment(html.to_s.gsub(%r{<br\s*/?>}i, "\n")).text)
  end

  private_class_method def self.clean_text(text)
    value = text&.to_s&.strip
    return if value.to_s.empty?

    value = value.gsub(/[ \t]+/, ' ')
    value = value.gsub(/\s*\n\s*/, "\n")
    value = value.gsub(/\n{3,}/, "\n\n")
    value unless value.to_s.empty?
  end

  private_class_method def self.joined_text(value)
    values = value.is_a?(Array) ? value : [value]
    text = values.filter_map { |item| present_text(item) }.join(', ')
    text unless text.empty?
  end

  private_class_method def self.present_text(text)
    value = text&.to_s&.strip
    value unless value.to_s.empty?
  end
end

# rubocop:enable Metrics/ClassLength
