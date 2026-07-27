# frozen_string_literal: true

require 'json'
require 'nokogiri'
require_relative '../utils/variables'
require_relative '../utils/chapter_label_formatter'
require_relative '../utils/error_response'
require_relative '../utils/http_client'

class NovelReadController
  extend ChapterLabelFormatter

  def self.fetch_read(novel_id, chapter_id)
    url = "#{Variables::ORIGIN}/novel/#{novel_id}/#{chapter_id}"
    response = HttpClient.get(url)
    raise "Failed to fetch novel chapter: Status #{response.code}" unless response.code == 200

    doc = Nokogiri::HTML(response.body)

    extract_read_from_next_data(doc, novel_id, chapter_id) || extract_read_from_dom(doc, novel_id, chapter_id)
  rescue StandardError => e
    ErrorResponse.build(
      "Error fetching novel chapter: #{e.message}",
      code: 'novel_chapter_fetch_failed',
      source: 'novel_read'
    )
  end

  private_class_method def self.extract_read_from_next_data(doc, novel_id, chapter_id)
    page_props = next_data_page_props(doc)
    chapter = page_props&.dig('chapter')
    content_html = chapter&.dig('content')
    return if content_html.to_s.empty?

    novel_title = present_text(chapter['title']) || dom_novel_title(doc)
    chapter_label = novel_chapter_label(chapter)

    {
      novel_id: novel_id,
      chapter_id: chapter['token']&.to_s || chapter_id,
      next_chapter_id: chapter_token(page_props['next']),
      prev_chapter_id: chapter_token(page_props['previous']),
      title: full_title(novel_title, chapter_label),
      chapter_title: chapter_label,
      content: html_to_text(content_html),
      content_html: content_html
    }
  end

  private_class_method def self.extract_read_from_dom(doc, novel_id, chapter_id)
    content_node = doc.at_css('[data-novel-content="true"]')
    return unless content_node

    novel_title = dom_novel_title(doc)
    chapter_label = dom_chapter_title(doc)
    content_html = content_node.inner_html.strip

    {
      novel_id: novel_id,
      chapter_id: chapter_id,
      next_chapter_id: nil,
      prev_chapter_id: nil,
      title: full_title(novel_title, chapter_label),
      chapter_title: chapter_label,
      content: html_to_text(content_html),
      content_html: content_html
    }
  end

  private_class_method def self.next_data_page_props(doc)
    script = doc.at_css('script#__NEXT_DATA__')
    return unless script

    JSON.parse(script.text).dig('props', 'pageProps')
  rescue JSON::ParserError
    nil
  end

  private_class_method def self.novel_chapter_label(chapter)
    format_chapter_label(
      'chapter' => chapter['chapter'],
      'title' => chapter['chapter_title']
    )
  end

  private_class_method def self.chapter_token(chapter)
    token = if chapter.is_a?(Hash)
              chapter['token'] || chapter[:token]
            else
              chapter
            end

    present_text(token)
  end

  private_class_method def self.dom_novel_title(doc)
    title = doc.at_css('p[class*="TopChapterNavbar_series_title"]')&.text&.strip
    return title unless title.to_s.empty?

    meta_title = doc.at_css('meta[property="og:title"]')&.[]('content')
    meta_title&.split(' - Chapter ')&.first || 'Unknown Novel'
  end

  private_class_method def self.dom_chapter_title(doc)
    title = doc.at_css('p[class*="TopChapterNavbar_chapter_title"]')&.text
    title = title&.gsub(/\s+/, ' ')&.strip
    title || 'Unknown Chapter'
  end

  private_class_method def self.full_title(novel_title, chapter_title)
    "#{novel_title} - #{chapter_title}"
  end

  private_class_method def self.html_to_text(html)
    text = Nokogiri::HTML.fragment(html.to_s.gsub(%r{<br\s*/?>}i, "\n")).text
    text.strip.gsub(/[ \t]+/, ' ').gsub(/\s*\n\s*/, "\n").gsub(/\n{3,}/, "\n\n")
  end

  private_class_method def self.present_text(text)
    value = text&.to_s&.strip
    value unless value.to_s.empty?
  end
end
