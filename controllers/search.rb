require_relative '../controllers/browse'

class SearchController
  def self.search_by_title(title)
    return { error: "Missing title parameter" } if title.nil? || title.strip.empty?

    data = BrowseController.fetch_series
    return data if data[:error]

    matches = data[:comics].select do |comic|
      comic[:title].downcase.include?(title.downcase)
    end

    {
      count: matches.length,
      results: matches
    }
  rescue StandardError => e
    { error: "Error performing search: #{e.message}" }
  end
end
