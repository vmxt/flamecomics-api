require 'httparty'
require 'nokogiri'
require_relative '../utils/variables'

class SeriesController
  def self.fetch_series(query_string = "")
    begin
      origin = Variables::ORIGIN
      url = "#{origin}/series/?#{query_string}"

      response = HTTParty.get(url)

      if response.code != 200
        raise "Failed to fetch data: Status #{response.code}"
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
          title: title || 'No Title',
          thumbnail: thumbnail || 'No Image',
          rating: rating == "1010" ? 10 : (rating.to_i if rating),
          status: status || 'Unknown'
        })
      end

      next_link = doc.at_css('a.r:contains("Next")')
      page_number = query_string.include?("page=") ? query_string.split("page=").last.to_i : 1
      next_page_number = next_link ? URI.parse(next_link.attr('href')).query&.split('=')&.last.to_i : nil

      response_data = {
        currentPage: page_number,
        type: URI.decode_www_form(URI.parse(url).query || '')&.to_h['type'] || 'All',
        status: URI.decode_www_form(URI.parse(url).query || '')&.to_h['status'] || 'All',
        order: URI.decode_www_form(URI.parse(url).query || '')&.to_h['order'] || 'Default',
        count: comics.length,
        comics: comics
      }

      response_data = { nextPage: next_page_number }.merge(response_data) if next_page_number

      response_data
    rescue StandardError => e
      { error: "Error fetching data: #{e.message}" }
    end
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
