# frozen_string_literal: true

require 'json'

module HomeCardExtractor
  CARD_SELECTOR = '.m_96bdd299.mantine-Grid-col'
  SERIES_TITLE_SELECTOR = 'h3 a[href^="/series/"], a.mantine-Text-root[data-size="md"][href^="/series/"], h3 span'

  private

  def extract_spotlight(doc)
    spotlight = extract_spotlight_from_next_data(doc)
    return spotlight unless spotlight.empty?

    dedupe_by_id(extract_spotlight_from_dom(doc))
  end

  def extract_spotlight_from_next_data(doc)
    script = doc.at_css('script#__NEXT_DATA__')
    return [] unless script

    carousel = JSON.parse(script.text).dig('props', 'pageProps', 'carousel')
    carousel.to_a.filter_map do |item|
      id = item['series_id']&.to_s
      title = item['title']&.strip
      image = item['image']
      next unless id && title && image

      {
        id: id,
        title: title,
        img_url: normalize_image_url("https://cdn.flamecomics.xyz/uploads/images/carousel/#{image}"),
        genres: item['categories'].to_a
      }
    end
  rescue JSON::ParserError
    []
  end

  def extract_spotlight_from_dom(doc)
    doc.css('div[data-orientation="horizontal"]').filter_map do |slide|
      link = slide.at_css('a[href^="/series/"]')
      href = link&.[]('href')
      id = href&.split('/')&.last
      next unless id

      title = slide.at_css('h2, h3')&.text&.strip
      next if title.to_s.empty?

      img_url = normalize_image_url(slide.at_css('img')&.[]('src'))
      next unless img_url

      genres = slide.css('a[href^="/genre/"] span')
                    .map { |genre| genre.text.strip }
                    .reject(&:empty?)
                    .uniq

      { id: id, title: title, img_url: img_url, genres: genres }
    end
  end

  def dedupe_by_id(items)
    items.each_with_object({}) do |item, result|
      result[item[:id]] ||= item
    end.values
  end

  def extract_cards(doc, selector)
    section = doc.at_css(selector)
    return [] unless section

    section.css(CARD_SELECTOR).filter_map do |elem|
      link = elem.at_css('a[href^="/series/"]')
      next unless link

      id = link['href']&.split('/')&.last
      title = elem.at_css(SERIES_TITLE_SELECTOR)&.text&.strip
      title = link['title']&.strip if title.to_s.empty?

      img_url = normalize_image_url(elem.at_css('img')&.[]('src'))
      next unless id && title && img_url

      {
        id: id,
        title: title,
        img_url: img_url,
        language: extract_language(elem),
        likes: parse_likes(elem.at_css('svg + span')&.text)
      }
    end
  end

  def extract_language(elem)
    language = elem.at_css('[data-nosnippet] span')&.text&.strip
    language if language && !language.empty?
  end

  def parse_likes(text)
    return unless text

    text.include?('K') ? (text.delete('K').to_f * 1000).to_i : text.gsub(/[^\d]/, '').to_i
  end
end
