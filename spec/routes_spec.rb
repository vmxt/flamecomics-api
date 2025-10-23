# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'FlamecomicsAPI Routes' do
  include Rack::Test::Methods

  def app
    FlamecomicsAPI.app
  end

  describe 'GET /' do
    it 'returns a welcome message' do
      get '/'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body["message"]).to match(/Flamecomics Manga scraper/)
    end
  end

  describe 'GET /home' do
    it 'returns home data' do
      allow(Home).to receive(:fetch_data).and_return({ "spotlight" => [], "popular" => [], "latest_updates" => [] })
      get '/home'
      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to include("spotlight", "popular", "latest_updates")
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
