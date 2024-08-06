require 'sinatra/base'
require 'json'
require_relative '../controllers/home'
require_relative '../controllers/details'
require_relative '../controllers/read'
require_relative '../controllers/search'
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

  get '/details/:id' do
    begin
      details = DetailsController.fetch_details(params[:id])
      details.to_json
    rescue StandardError => e
      status 500
      { error: "Error fetching data: #{e.message}" }.to_json
    end
  end

  get '/read/:id' do
    begin
      show_data = ReadController.fetch_read(params[:id])
      show_data.to_json
    rescue StandardError => e
      status 500
      { error: "Error fetching data: #{e.message}" }.to_json
    end
  end

  get '/search/:search' do
    begin
      search_results = SearchController.search(params[:search], params[:page] || 1)
      search_results.to_json
    rescue StandardError => e
      status 500
      { error: "Error fetching data: #{e.message}" }.to_json
    end
  end

  get '/series' do
    begin
      query_string = request.query_string
      series_data = SeriesController.fetch_series(query_string)
      series_data.to_json
    rescue StandardError => e
      status 500
      { error: "Error fetching data: #{e.message}" }.to_json
    end
  end
end
