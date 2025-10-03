require 'sinatra/base'
require 'json'
require_relative '../controllers/browse'
require_relative '../controllers/home'
require_relative '../controllers/read'
require_relative '../controllers/series'

class Routes < Sinatra::Base
  before do
    content_type :json
  end

  get '/' do
    {
      message: "Flamecomics Manga scraper",
      apiStatus: true,
      serverStatus: "ONLINE"
    }.to_json
  end

  get '/home' do
    Home.fetch_data.to_json
  rescue StandardError => e
    status 500
    { error: "Error fetching data: #{e.message}" }.to_json
  end

  get '/series/:id' do
    SeriesController.fetch_details(params[:id]).to_json
  rescue StandardError => e
    status 500
    { error: "Error fetching data: #{e.message}" }.to_json
  end

  get '/series/:series_id/:chapter_id' do
    ReadController.fetch_read(params[:series_id], params[:chapter_id]).to_json
  rescue StandardError => e
    status 500
    { error: "Error fetching data: #{e.message}" }.to_json
  end

  get '/browse' do
    query_string = request.query_string
    BrowseController.fetch_series(query_string).to_json
  rescue StandardError => e
    status 500
    { error: "Error fetching data: #{e.message}" }.to_json
  end
end
