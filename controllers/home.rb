require 'httparty'
require 'nokogiri'
require_relative '../utils/get_id_from_url'
require_relative '../utils/variables'

class HomeController
  def self.fetch_data
    begin
      url = Variables::ORIGIN

      if url.nil? || url.empty?
        raise 'Environment variable ORIGIN is not set or is empty'
      end

      response = HTTParty.get(url)
      if response.code != 200
        raise "Failed to fetch data: HTTP #{response.code}"
      end

      document = Nokogiri::HTML(response.body)
      spotlight = []
      trending = []
      latest_updates = []

            # Scrape swiper-slide section
            document.css('.swiper-slide').each do |elem|
              title = elem.css('.sliderinfo .tt').text.strip
              id = elem.css('a').attr('href').to_s.split('/').last
              img = elem.css('.bigbanner').attr('style').to_s.scan(/url\(['"](.+?)['"]\)/).flatten.first
              genres = elem.css('.slider-genres .sliderInfoGenre li').map(&:text).reject(&:empty?)
      
              next if title.empty? || id.empty? || img.nil? || genres.empty?
      
              spotlight << {
                'title' => title,
                'id' => id,
                'img' => img,
                'genre' => genres
              }
            end

      # Scrape bixbox.hothome section
      document.css('.bixbox.hothome').each do |elem|
        title = elem.css('h2').text.strip
        list = []

        elem.css('.pop-list-desktop .bs').each do |el|
          item = {}
          item['title'] = el.css('.tt').text.strip.empty? ? nil : el.css('.tt').text.strip
          item['id'] = el.css('a').attr('href').to_s.empty? ? nil : el.css('a').attr('href').to_s
          item['rating'] = el.css('.numscore').text.strip.empty? ? nil : el.css('.numscore').text.strip
          item['image'] = el.css('img').attr('src').to_s.empty? ? nil : el.css('img').attr('src').to_s
          item['status'] = el.css('.imptdt .status i').text.strip.empty? ? nil : el.css('.imptdt .status i').text.strip

          item['rating'] = item['rating'] == '1010' ? 10 : item['rating'] ? item['rating'][0].to_i : item['rating']
          item['id'] = get_id_from_url(item['id'], true) if item['id']

          list << item
        end

        trending << { 'title' => title, 'list' => list }
      end

      # Scrape latest-updates section
      document.css('.latest-updates .bs.styletere').each do |elem|
        title = elem.css('.info .tt').text.strip
        img = elem.css('.limit img').attr('src').to_s.empty? ? nil : elem.css('.limit img').attr('src').to_s
        rating = elem.css('.mobile-rt .numscore').text.strip.empty? ? nil : elem.css('.mobile-rt .numscore').text.strip.to_i
        status = elem.css('.imptdt .status i').text.strip.empty? ? nil : elem.css('.imptdt .status i').text.strip
        id = elem.css('a').attr('href').to_s.split('/').last

        chapters = elem.css('.chapter-list a').map do |chapter|
          chapter_title = chapter.css('.epxs').text.strip
          chapter_id = chapter.attr('href').split('/').last
          chapter_date = chapter.css('.epxdate').text.strip

          next if chapter_title.empty? || chapter_id.empty? || chapter_date.empty?

          {
            'title' => chapter_title,
            'id' => chapter_id,
            'date' => chapter_date
          }
        end.compact

        latest_updates << {
          'title' => title,
          'img' => img,
          'rating' => rating,
          'status' => status,
          'id' => id,
          'chapter' => chapters
        }
      end

      { 'spotlight' => spotlight, 'trending' => trending, 'latest_updates' => latest_updates }
    rescue StandardError => e
      { 'error' => "Error fetching data: #{e.message}" }
    end
  end
end
