# frozen_string_literal: true

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
      img_el = group.at_css('.DescSeriesCard_imageOuter__bKTXC img')
      stack_el = group.at_css('.mantine-Stack-root')
      next unless img_el && stack_el

      link_el = stack_el.at_css('a[href^="/series/"]')
      next unless link_el

      id = link_el['href'][%r{/series/(\d+)/?}, 1]
      title = link_el.text.strip

      # Avoid long safe navigation chains
      heart_el = stack_el.at_css('svg.bi-heart-fill')
      rating_el = nil
      if heart_el
        parent = heart_el.parent
        rating_el = parent.next_element if parent
      end
      rating = rating_el&.text&.strip&.to_i

      status_el = stack_el.at_css('.mantine-Badge-label')
      status = status_el&.text&.strip || 'Unknown'

      genres = stack_el.css('.DescSeriesCard_categories__adw1t .mantine-Badge-label')
                       .map(&:text)

      description = stack_el.at_css('.DescSeriesCard_description__ZOp0z p')&.text&.strip || 'No Description'
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
