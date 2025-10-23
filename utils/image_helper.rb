require 'uri'
require 'cgi'

module ImageHelper
  module_function

  def normalize_image_url(src)
    return nil if src.nil? || src.strip.empty?

    uri = begin
      URI.parse(src)
    rescue StandardError
      nil
    end
    return nil unless uri

    query = URI.decode_www_form(uri.query || '').to_h
    img = if query['url']
            CGI.unescape(query['url'])
          elsif src.start_with?('/')
            URI.join('https://cdn.flamecomics.xyz', src).to_s
          else
            src
          end

    return img if looks_like_image?(img)

    img
  rescue StandardError
    nil
  end

  def looks_like_image?(url)
    return false unless url&.match?(%r{\Ahttps?://}i)
    return true if url.match?(/\.(jpg|jpeg|png|gif|webp|avif)(\?.*)?$/i)
    return true if url.include?('cdn') || url.include?('flamecomics') || url.include?('kakaocdn')

    false
  end
end
