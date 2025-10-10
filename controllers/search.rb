require_relative '../controllers/browse'

class SearchController
  def self.search_by_title(title)
    return { error: "Missing title parameter" } if title.nil? || title.strip.empty?

    data = BrowseController.fetch_series
    return data if data[:error]

    normalized_input = normalize_text(title)

    matches = data[:comics].select do |comic|
      normalized_title = normalize_text(comic[:title])
      normalized_title.include?(normalized_input)
    end

    {
      count: matches.length,
      results: matches
    }
  rescue StandardError => e
    { error: "Error performing search: #{e.message}" }
  end

  private

  def self.normalize_text(text)
    text.unicode_normalize(:nfkd)
        .downcase
        .gsub(/[^a-z0-9\s]/i, ' ')
        .squeeze(' ')
        .strip
  end
end
