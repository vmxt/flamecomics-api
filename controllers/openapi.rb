# frozen_string_literal: true

class OpenAPIController
  def self.fetch
    {
      openapi: '3.0.3',
      info: {
        title: 'Flamecomics API',
        version: '1.0.0'
      },
      paths: paths,
      components: components
    }
  end

  def self.paths
    {
      '/' => path('API index and feature list'),
      '/openapi.json' => path('OpenAPI document'),
      '/health/scrapers' => path('Scraper reachability and data-shape diagnostics'),
      '/health/cache' => path('In-memory cache statistics'),
      '/home' => path('Home page sections'),
      '/browse' => path('Browse series'),
      '/search' => path('Search series by title'),
      '/series/{id}' => path('Series details'),
      '/series/{id}/{chapter_id}' => path('Chapter reader data'),
      '/random' => path('Redirect to a random valid series'),
      '/v1/home' => path('Versioned home page sections'),
      '/v1/browse' => path('Versioned browse series'),
      '/v1/search' => path('Versioned title search'),
      '/v1/series/{id}' => path('Versioned series details'),
      '/v1/series/{id}/{chapter_id}' => path('Versioned chapter reader data')
    }
  end
  private_class_method :paths

  def self.path(summary)
    {
      get: {
        summary: summary,
        responses: {
          '200' => {
            description: 'Successful response',
            content: {
              'application/json' => {
                schema: { type: 'object' }
              }
            }
          }
        }
      }
    }
  end
  private_class_method :path

  def self.components
    {
      schemas: {
        Error: {
          type: 'object',
          properties: {
            error: { type: 'string' },
            code: { type: 'string' },
            source: { type: 'string' }
          }
        }
      }
    }
  end
  private_class_method :components
end
