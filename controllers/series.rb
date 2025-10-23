require 'httparty'
require 'nokogiri'
require 'uri'
require_relative '../utils/variables'

class SeriesController
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

    img_src = doc.at_css('img.SeriesPage_cover__j6TrW')&.[]('src')
    poster_src = parse_image(img_src)

    chapters = doc.css('a.ChapterCard_chapterWrapper__YjOzx').map do |ch|
      href = ch['href']
      chapter_id = href&.sub(%r{^/series/#{id}/}, '')

      thumb_el = ch.at_css('.ChapterCard_chapterThumbnail__bik6B')
      thumb = extract_thumbnail(thumb_el)

      {
        chapter_id: chapter_id,
        img_url: thumb,
        label: ch.at_css('p[data-size="md"]')&.text&.strip || 'Unknown',
        date: ch.at_css('p[data-size="xs"]')&.text&.strip || 'Unknown'
      }
    end

    {
      title:,
      alternative_titles: alt_titles,
      poster_src:,
      genres:,
      type: info['Type'] || 'Unknown',
      status:,
      author: info['Author'] || 'Unknown',
      artist: info['Artist'] || 'Unknown',
      serialization: info['Publisher'] || 'Unknown',
      release_year: info['Release Year'] || 'Unknown',
      language: info['Language'] || 'Unknown',
      synopsis:,
      chapters_length: chapters.size,
      chapters:
    }
  rescue StandardError => e
    { error: "Error fetching details: #{e.message}" }
  end

  private_class_method def self.parse_image(src)
    return 'Unknown' unless src

    uri = begin
      URI.parse(src)
    rescue StandardError
      nil
    end
    return src unless uri&.query

    query = URI.decode_www_form(uri.query).to_h
    query['url'] ? CGI.unescape(query['url']) : src
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
