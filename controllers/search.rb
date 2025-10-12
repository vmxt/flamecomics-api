require_relative '../controllers/browse'

class SearchController
  def self.search_by_title(title)
    return { error: 'Missing title parameter' } if title.nil? || title.strip.empty?

    data = BrowseController.fetch_series
    return data if data[:error]

    query = normalize(title)
    results = data[:comics].select { |c| normalize(c[:title]).include?(query) }

    { count: results.size, results: results }
  rescue => e
    { error: "Error performing search: #{e.message}" }
  end

  private_class_method def self.normalize(text)
    text.unicode_normalize(:nfkd)
        .downcase
        .gsub(/[^a-z0-9\s]/, ' ')
        .squeeze(' ')
        .strip
  end
end
