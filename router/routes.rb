# frozen_string_literal: true

require 'roda'
require_relative '../controllers/browse'
require_relative '../controllers/home'
require_relative '../controllers/novel'
require_relative '../controllers/novel_read'
require_relative '../controllers/read'
require_relative '../controllers/series'
require_relative '../controllers/search'
require_relative '../controllers/random'
require_relative '../controllers/health'
require_relative '../controllers/index'
require_relative '../controllers/openapi'
require_relative '../utils/error_response'
require_relative '../utils/response_cache'

class Routes < Roda
  plugin :json
  plugin :all_verbs
  plugin :error_handler

  error do |e|
    response.status = 500
    ErrorResponse.build(e.message, code: 'internal_server_error', source: 'routes')
  end

  route do |routing|
    routing.root do
      IndexController.fetch
    end

    routing.get 'openapi.json' do
      OpenAPIController.fetch
    end

    routing.on 'v1' do
      route_api(routing)
    end

    route_api(routing)
  end

  private

  def route_api(routing)
    routing.on 'home' do
      cached('home') { Home.fetch_data }
    end

    routing.on 'health' do
      routing.get 'scrapers' do
        HealthController.scrapers
      end

      routing.get 'cache' do
        HealthController.cache
      end

      routing.delete 'cache' do
        HealthController.clear_cache
      end

      routing.get 'metrics' do
        HealthController.metrics
      end
    end

    routing.on 'series' do
      routing.get String, String do |series_id, chapter_id|
        ReadController.fetch_read(series_id, chapter_id)
      end

      routing.get String do |id|
        cached("series:#{id}") { SeriesController.fetch_details(id) }
      end
    end

    routing.on 'novel' do
      routing.get String, String do |novel_id, chapter_id|
        NovelReadController.fetch_read(novel_id, chapter_id)
      end

      routing.get String do |id|
        cached("novel:#{id}") { NovelController.fetch_details(id) }
      end
    end

    routing.on 'browse' do
      query_string = routing.env['QUERY_STRING']
      cached("browse:#{query_string}") { BrowseController.fetch_series(query_string) }
    end

    routing.on 'search' do
      routing.get do
        SearchController.search_by_title(routing.params['title'], routing.params)
      end
    end

    routing.on 'random' do
      id = RandomController.find_valid_id
      if id
        routing.redirect "/series/#{id}"
      else
        ErrorResponse.build('No valid series found', code: 'random_series_not_found', source: 'random')
      end
    end
  end

  def cached(key, &)
    response['Cache-Control'] = "public, max-age=#{ResponseCache::DEFAULT_TTL}"
    ResponseCache.fetch(key, &)
  end
end
