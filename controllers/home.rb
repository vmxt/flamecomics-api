require 'httparty'
require 'nokogiri'
require 'cgi'
require_relative '../utils/get_id_from_url'
require_relative '../utils/variables'

module Home
  extend self

  def fetch_data
    begin
      url = Variables::ORIGIN
      response = HTTParty.get(url)
      raise "Failed to fetch data: HTTP #{response.code}" if response.code != 200

      document = Nokogiri::HTML(response.body)
      spotlight = []
      popular = []
      latest_updates = []

      document.css('.mantine-Carousel-slide').each do |elem|
        title = elem.css('h3.Carousel_infoTitle__9V64e, h2.Carousel_infoTitle__9V64e').text.strip
        link = elem.at_css('a[href^="/series/"]')
        id = link ? link['href'].split('/').last : nil
        img_src = elem.at_css('img')&.[]('src')
        img_url = nil

        if img_src
          uri = URI.parse(img_src)
          query = URI.decode_www_form(uri.query || '').to_h
          img_url = query['url'] ? CGI.unescape(query['url']) :
                    (img_src.start_with?('/') ? URI.join('https://cdn.flamecomics.xyz', img_src).to_s : img_src)
        end

        genres = elem.css('.mantine-Badge-root a').map(&:text).map(&:strip).reject(&:empty?)
        next if title.empty? || id.nil? || img_url.nil? || genres.empty?

        spotlight << { 
          id:, 
          title:, 
          img_url:, 
          genres:
        }
      end

      if (popular_section = document.at_css('#popular'))
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
            img_url = query['url'] ? CGI.unescape(query['url']) :
                      (img_src.start_with?('/') ? URI.join('https://cdn.flamecomics.xyz', img_src).to_s : img_src)
          end

          status = elem.at_css('.mantine-Badge-root[data-variant="outline"] .mantine-Badge-label')&.text&.strip
          likes_text = elem.at_css('svg.bi-heart-fill')&.parent&.text&.strip
          likes = if likes_text
            if likes_text.include?('K')
              (likes_text.delete('K').to_f * 1000).to_i
            else
              likes_text.gsub(/[^\d]/, '').to_i
            end
          end

          next if title.empty? || id.nil? || img_url.nil?

          popular << {
            id: id,
            title: title,
            img_url: img_url,
            status: status,
            likes: likes
          }
        end
      end

      document.css('.m_96bdd299.mantine-Grid-col').each do |elem|
        series_title_a = elem.at_css('a.mantine-Text-root[data-size="md"]')
        title = series_title_a&.text&.strip
        id = series_title_a&.[]('href')&.split('/')&.last
        next if title.nil? || title.empty? || id.nil? || id.empty?

        img_src = elem.at_css('img')&.attr('src')
        img_url = nil
        if img_src
          uri = URI.parse(img_src) rescue nil
          if uri&.query
            query = URI.decode_www_form(uri.query).to_h
            img_url = CGI.unescape(query['url']) if query['url']
          end
          img_url ||= img_src.start_with?('/') ? URI.join('https://cdn.flamecomics.xyz', img_src).to_s : img_src
        end

        status = elem.at_css('.mantine-Badge-root[data-variant="outline"] .mantine-Badge-label')&.text&.strip

        chapters = elem.css("a[href*=\"/series/#{id}/\"]").map do |chapter_link|
          chapter_title = chapter_link.at_css('p')&.text&.strip
          chapter_id = chapter_link['href'].split('/').last
          chapter_date = chapter_link.at_css('p.SeriesCard_date__wbLsz')&.text&.strip
          next if chapter_title.nil? || chapter_title.empty? || chapter_id.nil? || chapter_id.empty? || chapter_date.nil? || chapter_date.empty?
          { chapter_id:, chapter_title:, chapter_date: }
        end.compact

        next if chapters.empty? || img_url.nil?

        latest_updates << { 
          id:, 
          title:, 
          img_url:, 
          status:, 
          chapters: 
        }
      end

      {
        'spotlight' => spotlight,
        'popular' => popular,
        'latest_updates' => latest_updates
      }

    rescue StandardError => e
      { error: "Error fetching data: #{e.message}" }
    end
  end
end
