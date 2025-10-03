require 'httparty'
require 'nokogiri'
require 'cgi'
require_relative '../utils/get_id_from_url'
require_relative '../utils/variables'

class HomeController
  def self.fetch_data
    begin
      url = Variables::ORIGIN
      raise 'Environment variable ORIGIN is not set or is empty' if url.nil? || url.empty?

      response = HTTParty.get(url)
      raise "Failed to fetch data: HTTP #{response.code}" if response.code != 200

      document = Nokogiri::HTML(response.body)
      spotlight = []
      popular = []
      latest_updates = []

      document.css('.mantine-Carousel-slide').each do |elem|
        title = elem.css('h2.Carousel_infoTitle__9V64e').text.strip
        link = elem.at_css('a[href^="/series/"]')
        id = link ? link['href'].split('/').last : nil

        img_src = elem.at_css('img')&.[]('src')
        img_url = nil

        if img_src
          uri = URI.parse(img_src)
          query = URI.decode_www_form(uri.query || '').to_h
          if query['url']
            img_url = CGI.unescape(query['url'])
          else
            img_url = img_src.start_with?('/') ? URI.join('https://cdn.flamecomics.xyz', img_src).to_s : img_src
          end
        end

        genres = elem.css('.mantine-Badge-root a').map { |a| a.text.strip }.reject(&:empty?)

        next if title.empty? || id.nil? || img_url.nil? || genres.empty?

        spotlight << {
          'title' => title,
          'id' => id,
          'img' => img_url,
          'genre' => genres
        }
      end

      popular_section = document.at_css('#Popular')
      if popular_section
        popular_section.css('.mantine-Grid-col').each do |elem|
          link = elem.at_css('a[href^="/series/"]')
          next unless link

          id = link['href'].split('/').last
          title = elem.at_css('p.mantine-Text-root')&.text&.strip || ''

          img_elem = elem.at_css('.SeriesCard_imageContainer__Tjx97 img')
          img_src = img_elem ? img_elem['src'] : nil
          img_url = nil

          if img_src
            uri = URI.parse(img_src)
            query = URI.decode_www_form(uri.query || '').to_h
            if query['url']
              img_url = CGI.unescape(query['url'])
            else
              img_url = img_src.start_with?('/') ? URI.join('https://cdn.flamecomics.xyz', img_src).to_s : img_src
            end
          end

          status = elem.at_css('.mantine-Badge-root[data-variant="outline"] .mantine-Badge-label')&.text&.strip
          likes_text = elem.at_css('svg.bi-heart-fill')&.parent&.text&.strip
          likes = likes_text.to_i if likes_text

          next if title.empty? || id.nil? || img_url.nil?

          popular << {
            'title' => title,
            'id' => id,
            'img' => img_url,
            'status' => status,
            'likes' => likes
          }
        end
      end

      document.css('.m_96bdd299.mantine-Grid-col').each do |elem|
        series_title_a = elem.at_css('a.mantine-Text-root[data-size="md"]')
        title = series_title_a ? series_title_a.text.strip : nil
        id = series_title_a ? series_title_a['href'].split('/').last : nil

        next if title.nil? || title.empty? || id.nil? || id.empty?

        img_src = elem.at_css('img')&.attr('src')
        img_url = nil

        if img_src
          uri = URI.parse(img_src) rescue nil
          if uri && uri.query
            query = URI.decode_www_form(uri.query).to_h
            if query['url']
              img_url = CGI.unescape(query['url'])
            end
          end

          if img_url.nil?
            img_url = img_src.start_with?('/') ? URI.join('https://cdn.flamecomics.xyz', img_src).to_s : img_src
          end
        end

        status = elem.at_css('.mantine-Badge-root[data-variant="outline"] .mantine-Badge-label')&.text&.strip

        chapters = elem.css("a[href*=\"/series/#{id}/\"]").map do |chapter_link|
          chapter_title = chapter_link.at_css('p')&.text&.strip
          chapter_id = chapter_link['href'].split('/').last
          chapter_date = chapter_link.at_css('p.SeriesCard_date__wbLsz')&.text&.strip

          next if chapter_title.nil? || chapter_title.empty? || chapter_id.nil? || chapter_id.empty? || chapter_date.nil? || chapter_date.empty?

          {
            'title' => chapter_title,
            'id' => chapter_id,
            'date' => chapter_date
          }
        end.compact

        next if chapters.empty? || img_url.nil?

        latest_updates << {
          'title' => title,
          'img' => img_url,
          'status' => status,
          'id' => id,
          'chapter' => chapters
        }
      end

      {
        'spotlight' => spotlight,
        'popular' => popular,
        'latest_updates' => latest_updates
      }
    rescue StandardError => e
      { 'error' => "Error fetching data: #{e.message}" }
    end
  end
end
