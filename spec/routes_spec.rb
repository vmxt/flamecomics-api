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
      fake_data = { count: 1, comics: [{ title: "One Piece" }] }
      allow(BrowseController).to receive(:fetch_series).and_return(fake_data)
      get '/browse'
      expect(last_response.status).to eq(200)
      body = JSON.parse(last_response.body)
      expect(body["comics"].first["title"]).to eq("One Piece")
    end
  end

  describe 'GET /invalid' do
    it 'returns 404 for invalid route' do
      get '/invalid'
      expect(last_response.status).to eq(404)
    end
  end
end
