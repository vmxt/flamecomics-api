# frozen_string_literal: true

require 'uri'
require_relative '../controllers/browse'
require_relative '../utils/error_response'

class SearchController
  DEFAULT_LIMIT = 20
  MAX_LIMIT = 100

  def self.search_by_title(title, params = {})
    if title.nil? || title.strip.empty?
      return ErrorResponse.build('Missing title parameter', code: 'missing_title', source: 'search')
    end

    query_string = browse_query(params)
    data = BrowseController.fetch_series(query_string)
    return data if data[:error]

    query = normalize(title)
    matches = data[:comics].filter_map do |comic|
      score = match_score(normalize(comic[:title]), query)
      comic.merge(score: score) if score.positive?
    end
    results = matches.sort_by { |comic| [-comic[:score], normalize(comic[:title])] }
    limit = bounded_limit(params['limit'])
    page = positive_integer(params['page']) || 1
    offset = (page - 1) * limit
    paginated_results = results.slice(offset, limit) || []

    {
      count: paginated_results.size,
      total_count: results.size,
      results: paginated_results,
      pagination: {
        page: page,
        limit: limit,
        next_page: offset + limit < results.size ? page + 1 : nil,
        prev_page: page > 1 ? page - 1 : nil,
        has_next_page: offset + limit < results.size
      },
      filters: {
        status: params['status'],
        genre: params['genre']
      }.compact
    }
  rescue StandardError => e
    ErrorResponse.build("Error performing search: #{e.message}", code: 'search_failed', source: 'search')
  end

  private_class_method def self.browse_query(params)
    URI.encode_www_form(
      params.slice('page', 'status', 'genre', 'type').reject { |_key, value| value.to_s.strip.empty? }
    )
  end

  private_class_method def self.bounded_limit(value)
    limit = positive_integer(value) || DEFAULT_LIMIT
    limit.clamp(1, MAX_LIMIT)
  end

  private_class_method def self.positive_integer(value)
    integer = value.to_i
    integer.positive? ? integer : nil
  end

  private_class_method def self.match_score(title, query)
    return 100 if title == query
    return 80 if title.include?(query)
    return 70 if query.split.all? { |term| title.include?(term) }

    distance = levenshtein_distance(title, query)
    max_length = [title.length, query.length].max
    similarity = max_length.zero? ? 0 : 1.0 - (distance.to_f / max_length)
    similarity >= 0.72 ? (similarity * 60).round : 0
  end

  private_class_method def self.levenshtein_distance(left, right)
    rows = Array.new(left.length + 1) { |index| [index] }
    (0..right.length).each { |index| rows[0][index] = index }

    (1..left.length).each do |i|
      (1..right.length).each do |j|
        cost = left[i - 1] == right[j - 1] ? 0 : 1
        rows[i][j] = [
          rows[i - 1][j] + 1,
          rows[i][j - 1] + 1,
          rows[i - 1][j - 1] + cost
        ].min
      end
    end

    rows[left.length][right.length]
  end

  private_class_method def self.normalize(text)
    text.unicode_normalize(:nfkd)
        .downcase
        .gsub(/[^a-z0-9\s]/, ' ')
        .squeeze(' ')
        .strip
  end
end
