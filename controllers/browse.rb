require 'httparty'
require 'nokogiri'
require 'cgi'
require 'uri'
require_relative '../utils/variables'
require_relative '../utils/image_helper'

class BrowseController
  def self.fetch_series(query_string = '')
    url = "#{Variables::ORIGIN}/browse?#{query_string}"
    response = HTTParty.get(url)
    raise "Failed to fetch data: Status #{response.code}" unless response.code == 200

    doc = Nokogiri::HTML(response.body)

    comics = doc.css('.mantine-Group-root').filter_map do |group|
      img_el = group.at_css('.DescSeriesCard_imageOuter__jCi_p img')
      stack_el = group.at_css('.mantine-Stack-root')
      next unless img_el && stack_el

      link = stack_el.at_css('a[href^="/series/"]')
      next unless link

      id = link['href'][%r{/series/(\d+)/?}, 1]
      title = link.text.strip
      heart_el = stack_el.at_css('.bi-heart-fill')
      rating_el = heart_el&.parent&.next_element
      rating_text = rating_el&.text
      rating = rating_text ? rating_text.strip.to_i : nil
      status = stack_el.at_css('.mantine-Badge-label')&.text&.strip || 'Unknown'
      genres = stack_el.css('.DescSeriesCard_categories__0736e .mantine-Badge-label')
                       .map { |g| g.text.strip }
      description = stack_el.at_css('.DescSeriesCard_description__XNkvv p')&.text&.strip || 'No Description'
      img_url = extract_image_url(img_el)

      {
        id: id,
        title: title,
        img_url: img_url,
        rating: rating,
        status: status,
        genres: genres,
        sypnosis: description
      }
    end

    { count: comics.size, comics: comics }
  rescue StandardError => e
    { error: "Error fetching data: #{e.message}" }
  end

  private_class_method def self.extract_image_url(img_el)
    src = img_el['src']
    srcset = img_el['srcset']

    chosen = if srcset && !srcset.empty?
               srcset.split(',').first&.split&.first
             else
               src
             end

    return unless chosen

    begin
      uri = URI.parse(chosen)
      query = URI.decode_www_form(uri.query || '').to_h
      if query['url']
        CGI.unescape(query['url'])
      else
        chosen.start_with?('/') ? URI.join('https://cdn.flamecomics.xyz', chosen).to_s : chosen
      end
    rescue URI::InvalidURIError
      chosen
    end
  end
end
