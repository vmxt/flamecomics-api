# frozen_string_literal: true

require 'json'
require_relative 'time_helper'

module HomeLatestUpdatesExtractor
  private

  def extract_latest_updates(doc)
    next_data_updates = extract_latest_updates_from_next_data(doc)
    return next_data_updates unless next_data_updates.empty?

    doc.css('.m_96bdd299.mantine-Grid-col').flat_map do |elem|
      extract_latest_update_card(elem)
    end.compact
  end

  def extract_latest_updates_from_next_data(doc)
    script = doc.at_css('script#__NEXT_DATA__')
    return [] unless script

    page_props = JSON.parse(script.text).dig('props', 'pageProps')
    blocks = page_props&.dig('latestEntries', 'blocks')
    return [] unless blocks

    blocks.flat_map { |block| block['series'].to_a }.flat_map do |series|
      extract_latest_update_from_series(series)
    end.compact
  rescue JSON::ParserError
    []
  end

  def extract_latest_update_card(elem)
    title_a = elem.at_css('a.mantine-Text-root[data-size="md"]')
    href = title_a&.[]('href')
    id = href&.split('/')&.last
    title = title_a&.text&.strip
    img_url = normalize_image_url(elem.at_css('img')&.[]('src'))
    chapters = extract_latest_update_chapters(elem)
    return unless id && title && img_url && !chapters.empty?

    base = {
      id: id,
      title: title,
      img_url: img_url,
      language: extract_language(elem)
    }

    chapters.map { |chapter| base.merge(chapter) }
  end

  def extract_latest_update_chapters(elem)
    links = elem.css('a[href^="/series/"]').select do |link|
      link['href'].split('/').length >= 4
    end

    links.map do |link|
      label = link.at_css('p')&.text&.strip
      {
        chapter_id: link['href'].split('/').last,
        chapter_title: label,
        chapter_date: extract_chapter_date(link)
      }
    end
  end

  def extract_latest_update_from_series(series)
    id = series['series_id']&.to_s
    title = series['title']&.strip
    chapters = next_data_chapters(series)
    return unless id && title && !chapters.empty?

    base = {
      id: id,
      title: title,
      img_url: latest_cover_url(series),
      language: series['country']
    }

    chapters.map { |chapter| base.merge(chapter) }
  end

  def next_data_chapters(series)
    series['chapters'].to_a.filter_map do |chapter|
      token = chapter['token']&.to_s
      next if token.empty?

      {
        chapter_id: token,
        chapter_title: format_chapter_label(chapter),
        chapter_date: format_release_date(chapter['release_date'])
      }
    end
  end

  def format_release_date(timestamp)
    return if timestamp.nil?

    TimeHelper.time_ago_in_words(Time.at(timestamp.to_i))
  end

  def latest_cover_url(series)
    id = series['series_id']
    cover = series['cover']
    return unless id && cover

    cache_buster = series['last_edit'] || series['time']
    url = "https://cdn.flamecomics.xyz/uploads/images/series/#{id}/#{cover}"
    url = "#{url}?#{cache_buster}" if cache_buster

    normalize_image_url(url)
  end
end
