require 'httparty'
require 'nokogiri'
require 'cgi'
require 'uri'
require_relative '../utils/variables'

class BrowseController
  def self.fetch_series(query_string = "")
    origin = Variables::ORIGIN
    url    = "#{origin}/browse?#{query_string}"

    response = HTTParty.get(url)
    raise "Failed to fetch data: Status #{response.code}" unless response.code == 200

    doc = Nokogiri::HTML(response.body)
    comics = []

    doc.css('.mantine-Group-root').each do |group|
      next unless group.at_css('.DescSeriesCard_imageOuter__jCi_p') && group.at_css('.mantine-Stack-root')

      img_el    = group.at_css('.DescSeriesCard_imageOuter__jCi_p img')
      stack_el  = group.at_css('.mantine-Stack-root')

      series_link = stack_el.at_css('a[href^="/series/"]')
      next unless series_link

      href     = series_link['href']
      id_match = href.match(%r{/series/(\d+)/?})
      id       = id_match ? id_match[1] : nil
      title    = series_link.text.strip

      rating_el = stack_el.at_css('.bi-heart-fill')&.parent&.next_element
      rating    = rating_el ? rating_el.text.strip.to_i : nil

      status_el = stack_el.at_css('.mantine-Badge-label')
      status    = status_el ? status_el.text.strip : 'Unknown'

      genres = stack_el.css('.DescSeriesCard_categories__0736e .mantine-Badge-label').map(&:text).map(&:strip)

      description = stack_el.at_css('.DescSeriesCard_description__XNkvv p')&.text&.strip || 'No Description'

      img_url = nil
      if img_el
        src     = img_el['src']
        srcset  = img_el['srcset']
        chosen  = nil

        if src && src.include?('/_next/image?')
          chosen = src
        elsif srcset
          first_src = srcset.split(',').map(&:strip).first&.split&.first
          chosen = first_src if first_src&.include?('/_next/image?')
        elsif src
          chosen = src
        end

        if chosen
          begin
            uri = URI.parse(chosen)
            query = URI.decode_www_form(uri.query || '').to_h
            if query['url']
              img_url = CGI.unescape(query['url'])
            else
              img_url = chosen.start_with?('/') ? URI.join('https://cdn.flamecomics.xyz', chosen).to_s : chosen
            end
          rescue URI::InvalidURIError
            img_url = chosen
          end
        end
      end

      comics << {
        id:,
        title:,
        img_url:,
        rating:,
        status:,
        genres:,
        sypnosis: description
      }
    end

    {
      count: comics.length,
      comics: comics
    }

  rescue StandardError => e
    { error: "Error fetching data: #{e.message}" }
  end
end
