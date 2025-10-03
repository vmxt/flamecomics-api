require 'httparty'
require 'nokogiri'
require 'uri'
require_relative '../utils/variables'

class SeriesController
  def self.fetch_details(id)
    begin
      url = "#{Variables::ORIGIN}/series/#{id}"
      response = HTTParty.get(url)
      raise "Failed to fetch details: Status #{response.code}" unless response.code == 200

      document = Nokogiri::HTML(response.body)

      title = document.at_css('h1.mantine-Title-root')&.text&.strip || 'Unknown'
      alternative_titles = document.at_css('.SeriesPage_altTitles__UI8Ij')&.text&.strip || 'Unknown'

      status = document.css('.mantine-Badge-root').find { |badge|
        badge.text.strip.match?(/Ongoing|Dropped|Completed/i)
      }&.text&.strip || 'Unknown'

      genres = document.css('.SeriesPage_badge__ZSRhM span.mantine-Badge-label').map do |g|
        g.text.strip
      end

      raw_synopsis = document.css('div.SeriesPage_paper__mf3li p.mantine-Text-root').find { |p|
        p.inner_html.include?('&lt;p&gt;')
      }&.inner_html || ''
      synopsis = Nokogiri::HTML.fragment(raw_synopsis.gsub('&lt;', '<').gsub('&gt;', '>')).text.strip rescue 'Unknown'

      info = {}
      document.css('div.SeriesPage_paper__mf3li').each do |div|
        key = div.at_css('p.SeriesPage_infoField__KolqF')&.text&.strip
        val = div.at_css('p.SeriesPage_infoValue__kbVfH')&.text&.strip
        info[key] = val if key && val
      end

      author = info['Author'] || 'Unknown'
      artist = info['Artist'] || 'Unknown'
      serialization = info['Publisher'] || 'Unknown'
      type = info['Type'] || 'Unknown'
      release_year = info['Release Year'] || 'Unknown'
      language = info['Language'] || 'Unknown'

      official_url = document.at_css('a.mantine-Button-root[href*="manga.bilibili.com/detail"]')&.[]('href') || 'Unknown'

      img_src = document.at_css('img.SeriesPage_cover__j6TrW')&.[]('src')
      poster_src = 'Unknown'
      if img_src
        query = img_src.split('?')[1]
        if query
          params = URI.decode_www_form(query)
          url_param = params.find { |k, _| k == 'url' }
          poster_src = url_param[1] if url_param
        end
      end

      chapters = document.css('a.ChapterCard_chapterWrapper__YjOzx').map do |ch|
        href = ch['href']
        chapter_id = href&.sub(%r{^/series/#{id}/}, '')

        thumbnail_elem = ch.at_css('.ChapterCard_chapterThumbnail__bik6B img')
        if thumbnail_elem
          thumbnail_url = thumbnail_elem['src']
        else
          style = ch.at_css('.ChapterCard_chapterThumbnail__bik6B')&.[]('style') || ''
          thumbnail_url = style.match(/url\(['"]?(.*?)['"]?\)/)&.captures&.first
        end

        {
          id: chapter_id,
          img: thumbnail_url,
          label: ch.at_css('p[data-size="md"]')&.text&.strip || 'Unknown',
          date: ch.at_css('p[data-size="xs"]')&.text&.strip || 'Unknown'
        }
      end

      {
        title: title,
        alternativeTitles: alternative_titles,
        posterSrc: poster_src,
        genres: genres,
        type: type,
        status: status,
        author: author,
        artist: artist,
        serialization: serialization,
        releaseYear: release_year,
        language: language,
        officialUrl: official_url,
        synopsis: synopsis,
        chaptersCount: chapters.length,
        chapters: chapters
      }

    rescue StandardError => e
      { error: "Error fetching details: #{e.message}" }
    end
  end
end
