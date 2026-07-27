# frozen_string_literal: true

require 'json'

module HomeNovelExtractor
  NOVEL_CARD_SELECTOR = '.m_96bdd299.mantine-Grid-col'
  NOVEL_TITLE_SELECTOR = 'h3 a[href^="/novel/"], a.mantine-Text-root[data-size="md"][href^="/novel/"], h3 span'
  NOVEL_SECTION_HEADINGS = ['Latest Novels', 'Novels'].freeze

  private

  def extract_novels(doc)
    next_data_novels = extract_novels_from_next_data(doc)
    return next_data_novels unless next_data_novels.empty?

    section = find_novel_section(doc)
    return [] unless section

    extract_novel_cards(section)
  end

  def extract_novels_from_next_data(doc)
    script = doc.at_css('script#__NEXT_DATA__')
    return [] unless script

    page_props = JSON.parse(script.text).dig('props', 'pageProps')
    blocks = page_props&.dig('latestNovels', 'blocks')
    blocks = page_props&.dig('novels', 'blocks') if blocks.to_a.empty?

    extract_novel_entries(blocks)
  rescue JSON::ParserError
    []
  end

  def extract_novel_entries(blocks)
    blocks.to_a.flat_map { |block| block['series'].to_a }.filter_map do |novel|
      id = (novel['novel_id'] || novel['series_id'])&.to_s
      title = novel['title']&.strip
      img_url = novel_cover_url(novel, id)
      next if id.to_s.empty? || title.to_s.empty? || !img_url

      {
        id: id,
        title: title,
        img_url: img_url,
        language: present_text(novel['country']),
        likes: novel['likes'],
        status: present_text(novel['status'])
      }
    end
  end

  def novel_cover_url(novel, id)
    cover = novel['cover']
    return if id.to_s.empty? || cover.to_s.empty?

    cache_buster = novel['last_edit'] || novel['time']
    url = "https://cdn.flamecomics.xyz/uploads/images/novels/#{id}/#{cover}"
    url = "#{url}?#{cache_buster}" if cache_buster

    normalize_image_url(url)
  end

  def find_novel_section(doc)
    doc.at_css('#novels') || section_after_heading(doc, NOVEL_SECTION_HEADINGS)
  end

  def section_after_heading(doc, headings)
    heading = doc.css('h1, h2, h3, h4, [class*="Title"]').find do |node|
      headings.include?(node.text.strip)
    end
    return unless heading

    node = heading.next_element
    while node
      return node if node.css(NOVEL_CARD_SELECTOR).any?
      break if section_heading?(node, headings)

      node = node.next_element
    end
  end

  def section_heading?(node, current_headings)
    %w[h1 h2 h3 h4].include?(node.name) && !current_headings.include?(node.text.strip)
  end

  def extract_novel_cards(section)
    section.css(NOVEL_CARD_SELECTOR).filter_map do |elem|
      link = elem.at_css('a[href^="/novel/"]')
      next unless link

      id = link['href']&.split('/')&.last
      title = elem.at_css(NOVEL_TITLE_SELECTOR)&.text&.strip
      title = link['title']&.strip if title.to_s.empty?
      img_url = normalize_image_url(elem.at_css('img')&.[]('src'))
      next unless id && title && img_url

      {
        id: id,
        title: title,
        img_url: img_url,
        language: extract_language(elem),
        likes: parse_likes(elem.at_css('svg + span')&.text),
        status: present_text(elem.css('.mantine-Badge-label').last&.text)
      }
    end
  end

  def present_text(text)
    value = text&.to_s&.strip
    value unless value.to_s.empty?
  end
end
