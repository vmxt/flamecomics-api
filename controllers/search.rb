require 'httparty'
require 'nokogiri'
require_relative '../utils/get_id_from_url'
require_relative '../utils/variables'

class SearchController
  def self.search(query, page = 1)
    begin
      url = "#{Variables::ORIGIN}/page/#{page}?s=#{URI.encode_www_form_component(query)}"
      response = HTTParty.get(url)

      if response.code != 200
        raise "Failed to fetch data: Status #{response.code}"
      end

      data = response.body
      if data.nil? || data.empty?
        raise 'Received empty response data'
      end

      document = Nokogiri::HTML(data)

      results = { results: [] }

      document.css('.bsx a').each do |element|
        title_element = element.at_css('.tt')
        title = title_element ? title_element.text.strip : 'No Title'

        id = get_id_from_url(element['href'], true)

        rating_element = element.at_css('.numscore')
        rating = rating_element ? rating_element.text.strip : '0'

        status_element = element.at_css('.status i')
        status = status_element ? status_element.text.strip : 'Unknown'

        image_element = element.at_css('.ts-post-image')
        image = image_element ? image_element['src'] : 'No Image'

        results[:results] << {
          title: title,
          id: id,
          rating: rating == '1010' ? 10 : rating.to_i,
          status: status,
          image: image
        }
      end

      if results[:results].empty?
        { message: 'No Results Found' }
      else
        {
          page: page.to_i,
          count: results[:results].length,
          results: results[:results]
        }
      end
    rescue StandardError => e
      { error: "Error fetching data: #{e.message}" }
    end
  end
end
