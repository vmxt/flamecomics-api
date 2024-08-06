require 'httparty'
require 'nokogiri'
require_relative '../utils/variables'

class ReadController
  def self.fetch_read(id)
    begin
      url = "#{Variables::ORIGIN}#{id}"
      response = HTTParty.get(url)

      if response.code != 200
        raise "Status: #{response.code}"
      end

      data = response.body
      if data.nil? || data.empty?
        raise 'Data is null'
      end

      document = Nokogiri::HTML(data)

      img_srcs = []
      title = document.at_css('h1.entry-title').text.strip

      document.css('p img').each do |img|
        src = img['src']
        next if src.nil?
        next if src.include?('https://flamecomics.com/wp-content/uploads/2022/05/readonflamescans.png') ||
                src.include?('https://flamecomics.com/wp-content/uploads/2022/07/999black-KTL.jpg') ||
                src.include?('999black-KTL') ||
                src.include?('readonflamecomics')

        img_srcs << src
      end

      prev_id = id.sub(/\d+$/) { |match| (match.to_i - 1).to_s }
      next_id = id.sub(/\d+$/) { |match| (match.to_i + 1).to_s }

      {
        id: id,
        prevId: prev_id,
        nextId: next_id,
        title: title,
        count: img_srcs.length,
        imgSrcs: img_srcs
      }
    rescue StandardError => e
      { error: "Error fetching data: #{e.message}" }
    end
  end
end
