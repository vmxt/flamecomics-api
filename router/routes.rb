require 'roda'
require_relative '../controllers/browse'
require_relative '../controllers/home'
require_relative '../controllers/read'
require_relative '../controllers/series'
require_relative '../controllers/search'

class Routes < Roda
  plugin :json
  plugin :all_verbs

  route do |r|
    r.root do
      { message: 'Flamecomics Manga scraper', apiStatus: true, serverStatus: 'ONLINE' }
    end

    r.on "home" do
      begin
        Home.fetch_data
      rescue => e
        response.status = 500
        { error: e.message }
      end
    end

    r.on "series" do
      r.get String do |id|
        begin
          SeriesController.fetch_details(id)
        rescue => e
          response.status = 500
          { error: e.message }
        end
      end

      r.get String, String do |series_id, chapter_id|
        begin
          ReadController.fetch_read(series_id, chapter_id)
        rescue => e
          response.status = 500
          { error: e.message }
        end
      end
    end

    r.on "browse" do
      begin
        query_string = r.env['QUERY_STRING']
        BrowseController.fetch_series(query_string)
      rescue => e
        response.status = 500
        { error: e.message }
      end
    end

    r.on "search" do
      r.get do
        begin
          title = r.params["title"]
          SearchController.search_by_title(title)
        rescue => e
          response.status = 500
          { error: e.message }
        end
      end
    end
  end
end
