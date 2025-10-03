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
    begin
      data = HomeController.fetch_data
      data.to_json
    rescue StandardError => e
      status 500
      { error: "Error fetching data: #{e.message}" }.to_json
    end
  end

  get '/series/:id' do
    begin
      details = SeriesController.fetch_details(params[:id])
      details.to_json
    rescue StandardError => e
      status 500
      { error: "Error fetching data: #{e.message}" }.to_json
    end
  end

  get '/series/:series_id/:chapter_id' do
    begin
      data = ReadController.fetch_read(params[:series_id], params[:chapter_id])
      data.to_json
    rescue StandardError => e
      status 500
      { error: "Error fetching data: #{e.message}" }.to_json
    end
  end

  get '/browse' do
    begin
      query_string = request.query_string
      series_data = BrowseController.fetch_series(query_string)
      series_data.to_json
    rescue StandardError => e
      status 500
      { error: "Error fetching data: #{e.message}" }.to_json
    end
  end
end
