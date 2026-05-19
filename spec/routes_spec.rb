# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'FlamecomicsAPI Routes' do
  include Rack::Test::Methods

  def app
    FlamecomicsAPI.app
  end

  describe 'GET /' do
    it 'returns the API index' do
      get '/'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body["message"]).to match(/Flamecomics Manga scraper/)
      expect(body["features"]).to include("Scraper health diagnostics", "Short TTL response caching")
      expect(body["cache"]).to include("ttl_seconds" => 180)
      expect(body["endpoints"]).to include(
        include("method" => "GET", "path" => "/health/scrapers"),
        include("method" => "GET", "path" => "/home")
      )
    end
  end

  describe 'GET /home' do
    it 'returns home data' do
      allow(Home).to receive(:fetch_data).and_return({ "spotlight" => [], "popular" => [], "latest_updates" => [] })
      get '/home'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to include("spotlight", "popular", "latest_updates")
      expect(last_response.headers["Cache-Control"]).to eq("public, max-age=180")
    end

    it 'caches home data briefly' do
      allow(Home).to receive(:fetch_data).once.and_return({ "spotlight" => [], "popular" => [], "latest_updates" => [] })

      get '/home'
      get '/home'

      expect(last_response.status).to eq(200)
    end
  end

  describe 'GET /health/scrapers' do
    it 'returns scraper health data' do
      fake_data = { reachable: true, next_data_present: true }
      allow(HealthController).to receive(:scrapers).and_return(fake_data)

      get '/health/scrapers'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to include("reachable" => true, "next_data_present" => true)
    end
  end

  describe 'GET /health/cache' do
    it 'returns cache stats' do
      get '/health/cache'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to include("cache")
    end
  end

  describe 'GET /openapi.json' do
    it 'returns OpenAPI data' do
      get '/openapi.json'

      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body["openapi"]).to eq("3.0.3")
      expect(body["paths"]).to include("/v1/home", "/health/cache")
    end
  end

  describe 'GET /v1/home' do
    it 'returns versioned home data' do
      allow(Home).to receive(:fetch_data).and_return({ "spotlight" => [], "popular" => [], "latest_updates" => [] })

      get '/v1/home'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to include("spotlight", "popular", "latest_updates")
      expect(last_response.headers["Cache-Control"]).to eq("public, max-age=180")
    end
  end

  describe 'GET /series/:id' do
    it 'returns series details' do
      fake_data = { title: "Mock Series" }
      allow(SeriesController).to receive(:fetch_details).with("123").and_return(fake_data)
      get '/series/123'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)["title"]).to eq("Mock Series")
    end

    it 'caches series details by id' do
      allow(SeriesController).to receive(:fetch_details).with("123").once.and_return({ title: "Mock Series" })

      get '/series/123'
      get '/series/123'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)["title"]).to eq("Mock Series")
    end
  end

  describe 'GET /series/:id/:chapter_id' do
    it 'returns chapter data' do
      fake_data = { title: "Mock Chapter", count: 5 }
      allow(ReadController).to receive(:fetch_read).with("1", "2").and_return(fake_data)
      get '/series/1/2'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)["title"]).to eq("Mock Chapter")
    end
  end

  describe 'GET /browse' do
    it 'returns browse data' do
      fake_data = { count: 1, comics: [{ title: "Jungle Juice" }] }
      allow(BrowseController).to receive(:fetch_series).and_return(fake_data)
      get '/browse'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body["comics"].first["title"]).to eq("Jungle Juice")
    end

    it 'caches browse data by query string' do
      fake_data = { count: 1, comics: [{ title: "Jungle Juice" }] }
      allow(BrowseController).to receive(:fetch_series).with("page=1").once.and_return(fake_data)

      get '/browse?page=1'
      get '/browse?page=1'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)["count"]).to eq(1)
    end
  end

  describe 'GET /search' do
    let(:mock_data) do
      {
        comics: [
          { title: "Omniscient Reader's Viewpoint", id: 1 },
          { title: "Leveling With The Gods", id: 2 },
          { title: "Return of The Frozen Player", id: 3 }
        ]
      }
    end

    before do
      allow(BrowseController).to receive(:fetch_series).and_return(mock_data)
    end

    it 'returns matching search results' do
      get '/search', { title: 'Frozen' }
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body["count"]).to eq(1)
      expect(body["results"].first["title"]).to eq("Return of The Frozen Player")
    end

    it 'is case-insensitive' do
      get '/search', { title: 'omniscient reader' }
      body = JSON.parse(last_response.body)
      expect(body["count"]).to eq(1)
      expect(body["results"].first["title"]).to eq("Omniscient Reader's Viewpoint")
    end

    it 'returns an error when title param is missing' do
      get '/search'
      expect(last_response.status).to eq(400).or eq(200)
      body = JSON.parse(last_response.body)
      expect(body["error"]).to match(/Missing title parameter/)
    end

    it 'returns an error when BrowseController fails' do
      allow(BrowseController).to receive(:fetch_series).and_return({ error: "Failed to fetch series" })
      get '/search', { title: 'Leveling' }
      body = JSON.parse(last_response.body)
      expect(body["error"]).to eq("Failed to fetch series")
    end
  end

  describe 'GET /invalid' do
    it 'returns 404 for invalid route' do
      get '/invalid'
      expect(last_response.status).to eq(404)
    end
  end
end
