# frozen_string_literal: true

require_relative '../controllers/browse'
require_relative '../utils/error_response'

class SearchController
  def self.search_by_title(title)
    if title.nil? || title.strip.empty?
      return ErrorResponse.build('Missing title parameter', code: 'missing_title', source: 'search')
    end

    data = BrowseController.fetch_series
    return data if data[:error]

    query = normalize(title)
    results = data[:comics].select { |c| normalize(c[:title]).include?(query) }

    { count: results.size, results: results }
  rescue StandardError => e
    ErrorResponse.build("Error performing search: #{e.message}", code: 'search_failed', source: 'search')
  end

  private_class_method def self.normalize(text)
    text.unicode_normalize(:nfkd)
        .downcase
        .gsub(/[^a-z0-9\s]/, ' ')
        .squeeze(' ')
        .strip
  end
end
