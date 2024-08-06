require 'httparty'
require 'nokogiri'
require_relative '../utils/variables'

class SeriesController
  def self.fetch_series(query_string = "")
    origin = Variables::ORIGIN
    url = "#{origin}/series/?#{query_string}"
    
    response = HTTParty.get(url)
    
    if response.code != 200
      raise "Status: #{response.code}"
    end

    data = response.body
    doc = Nokogiri::HTML(data)

    comics = []

    doc.css('.bsx a').each do |el|
      title = el.at_css('.tt')&.text&.strip
      thumbnail = el.at_css('img')&.attr('src')
      rating = el.at_css('.numscore')&.text
      status = el.at_css('.status i')&.text
      id = get_id_from_url(el.attr('href'), true)

      comics.push({
        id: id,
        title: title,
        thumbnail: thumbnail,
        rating: rating == "1010" ? 10 : rating.to_i,
        status: status
      })
    end

    next_link = doc.at_css('a.r:contains("Next")')
    page_number = url.include?("page=") ? url.split("page=").last.to_i : 1
    next_page_number = next_link ? URI.parse(next_link.attr('href')).query&.split('=')&.last.to_i : nil

    {
      currentPage: page_number,
      nextPage: next_page_number,
      type: URI.decode_www_form(URI.parse(url).query || '')&.to_h['type'] || 'All',
      status: URI.decode_www_form(URI.parse(url).query || '')&.to_h['status'] || 'All',
      order: URI.decode_www_form(URI.parse(url).query || '')&.to_h['order'] || 'Default',
      count: comics.length,
      comics: comics
    }
  rescue StandardError => e
    puts e.message
    { error: e.message }
  end

  private

  def self.get_id_from_url(str, for_series = false)
    if for_series
      match = str.match(%r{/series/(?:\d+-)?(.+)/})
      match ? match[1].tr('/', '') : nil
    else
      match = str.match(%r{/([^/]+)/$})
      match ? match[1].tr('-', '-') : nil
    end
  end
end
