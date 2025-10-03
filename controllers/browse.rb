require 'httparty'
require 'nokogiri'
require_relative '../utils/variables'

class BrowseController
  def self.fetch_series(query_string = "")
    begin
      origin = Variables::ORIGIN
      url = "#{origin}/browse?#{query_string}"

      response = HTTParty.get(url)
      raise "Failed to fetch data: Status #{response.code}" unless response.code == 200

      doc = Nokogiri::HTML(response.body)
      comics = []

      doc.css('.mantine-Stack-root').each do |el|
        series_link = el.at_css('a[href^="/series/"]')
        next unless series_link

        href = series_link['href']
        id_match = href.match(%r{/series/(\d+)/?})
        id = id_match ? id_match[1] : nil
        series_url = "#{origin}#{href}"
        title = series_link.text.strip
        rating_el = el.at_css('.bi-heart-fill')&.parent&.next_element
        rating = rating_el ? rating_el.text.strip.to_i : nil
        status_el = el.at_css('.mantine-Badge-label')
        status = status_el ? status_el.text.strip : 'Unknown'
        genres = el.css('.DescSeriesCard_categories__0736e .mantine-Badge-label').map { |g| g.text.strip }
        desc = el.at_css('.DescSeriesCard_description__XNkvv p')&.text&.strip || 'No Description'
        thumbnail = el.at_css('img')&.attr('src') || 'No Image'

        comics.push({
          id: id,
          title: title,
          series_url: series_url,
          thumbnail: thumbnail,
          rating: rating,
          status: status,
          genres: genres,
          description: desc
        })
      end

      next_link = doc.css('a.r').find { |a| a.text.strip.downcase.include?('next') }
      page_number = query_string.include?("page=") ? query_string.split("page=").last.to_i : 1
      next_page_number = next_link ? page_number + 1 : nil

      {
        currentPage: page_number,
        count: comics.length,
        comics: comics
      }
    rescue StandardError => e
      { error: "Error fetching data: #{e.message}" }
    end
  end
end
