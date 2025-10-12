require 'roda'
require_relative '../controllers/browse'
require_relative '../controllers/home'
require_relative '../controllers/read'
require_relative '../controllers/series'
require_relative '../controllers/search'

class Routes < Roda
  plugin :json
  plugin :all_verbs
  plugin :error_handler

  error do |e|
    response.status = 500
    { error: e.message }
  end

  route do |r|
    r.root do
      { message: 'Flamecomics Manga scraper', apiStatus: true, serverStatus: 'ONLINE' }
    end

    r.on "home" do
      Home.fetch_data
    end

    r.on "series" do
      r.get String, String do |series_id, chapter_id|
        ReadController.fetch_read(series_id, chapter_id)
      end

      r.get String do |id|
        SeriesController.fetch_details(id)
      end
    end

    r.on "browse" do
      BrowseController.fetch_series(r.env['QUERY_STRING'])
    end

    r.on "search" do
      r.get do
        SearchController.search_by_title(r.params["title"])
      end
    end
  end
end
