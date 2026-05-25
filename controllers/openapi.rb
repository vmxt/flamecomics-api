# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

class OpenAPIController
  def self.fetch
    {
      openapi: '3.0.3',
      info: {
        title: 'Flamecomics API',
        version: '1.1.0'
      },
      paths: paths,
      components: components
    }
  end

  def self.paths
    {
      '/' => endpoint('API index and feature list', schema_ref('Index')),
      '/openapi.json' => endpoint('OpenAPI document', { type: 'object' }),
      '/health/scrapers' => endpoint('Scraper reachability and data-shape diagnostics', schema_ref('ScraperHealth')),
      '/health/cache' => health_cache_endpoint,
      '/health/metrics' => endpoint('Request, cache, and upstream metrics', schema_ref('MetricsHealth')),
      '/home' => endpoint('Home page sections', schema_ref('Home')),
      '/browse' => browse_endpoint,
      '/search' => search_endpoint,
      '/series/{id}' => series_endpoint,
      '/series/{id}/{chapter_id}' => reader_endpoint,
      '/random' => endpoint('Redirect to a random valid series', schema_ref('Error'), responses: redirect_responses),
      '/v1/home' => endpoint('Versioned home page sections', schema_ref('Home')),
      '/v1/browse' => browse_endpoint,
      '/v1/search' => search_endpoint,
      '/v1/series/{id}' => series_endpoint,
      '/v1/series/{id}/{chapter_id}' => reader_endpoint
    }
  end
  private_class_method :paths

  def self.health_cache_endpoint
    endpoint('In-memory or Redis cache statistics', schema_ref('CacheHealth')).merge(
      delete: operation('Clear cached scraper responses', schema_ref('CacheClear'))
    )
  end
  private_class_method :health_cache_endpoint

  def self.browse_endpoint
    endpoint(
      'Browse series',
      schema_ref('Browse'),
      parameters: [
        query_parameter('page', 'Browse page number', schema: { type: 'integer', minimum: 1 }),
        query_parameter('status', 'Series status filter', schema: { type: 'string' }),
        query_parameter('genre', 'Genre filter', schema: { type: 'string' }),
        query_parameter('type', 'Series type filter', schema: { type: 'string' })
      ]
    )
  end
  private_class_method :browse_endpoint

  def self.search_endpoint
    endpoint(
      'Search series by title',
      schema_ref('Search'),
      parameters: [
        query_parameter('title', 'Case-insensitive title query', required: true),
        query_parameter('limit', 'Maximum results per page', schema: { type: 'integer', minimum: 1, maximum: 100 }),
        query_parameter('page', 'Search result page number', schema: { type: 'integer', minimum: 1 }),
        query_parameter('status', 'Browse status filter', schema: { type: 'string' }),
        query_parameter('genre', 'Browse genre filter', schema: { type: 'string' })
      ]
    )
  end
  private_class_method :search_endpoint

  def self.series_endpoint
    endpoint(
      'Series details',
      schema_ref('Series'),
      parameters: [path_parameter('id', 'Series id')]
    )
  end
  private_class_method :series_endpoint

  def self.reader_endpoint
    endpoint(
      'Chapter reader data',
      schema_ref('Reader'),
      parameters: [
        path_parameter('id', 'Series id'),
        path_parameter('chapter_id', 'Chapter token/id')
      ]
    )
  end
  private_class_method :reader_endpoint

  def self.endpoint(summary, schema, parameters: [], responses: nil)
    {
      get: operation(summary, schema, parameters: parameters, responses: responses)
    }
  end
  private_class_method :endpoint

  def self.operation(summary, schema, parameters: [], responses: nil)
    {
      summary: summary,
      parameters: parameters,
      responses: responses || json_responses(schema)
    }.compact
  end
  private_class_method :operation

  def self.json_responses(schema)
    {
      '200' => {
        description: 'Successful response',
        content: {
          'application/json' => {
            schema: schema
          }
        }
      },
      '500' => {
        description: 'Structured error response',
        content: {
          'application/json' => {
            schema: schema_ref('Error')
          }
        }
      }
    }
  end
  private_class_method :json_responses

  def self.redirect_responses
    {
      '302' => { description: 'Redirect to /series/{id}' },
      '200' => {
        description: 'No valid random series found',
        content: {
          'application/json' => {
            schema: schema_ref('Error')
          }
        }
      }
    }
  end
  private_class_method :redirect_responses

  def self.query_parameter(name, description, required: false, schema: { type: 'string' })
    {
      name: name,
      in: 'query',
      required: required,
      description: description,
      schema: schema
    }
  end
  private_class_method :query_parameter

  def self.path_parameter(name, description)
    {
      name: name,
      in: 'path',
      required: true,
      description: description,
      schema: { type: 'string' }
    }
  end
  private_class_method :path_parameter

  def self.schema_ref(name)
    { '$ref' => "#/components/schemas/#{name}" }
  end
  private_class_method :schema_ref

  def self.components
    {
      schemas: {
        Error: object_schema(
          error: { type: 'string' },
          code: { type: 'string' },
          source: { type: 'string' }
        ),
        ComicSummary: object_schema(
          id: { type: 'string' },
          title: { type: 'string' },
          img_url: { type: 'string', nullable: true },
          rating: { type: 'integer' },
          status: { type: 'string' },
          genres: array_schema({ type: 'string' }),
          synopsis: { type: 'string' }
        ),
        Chapter: object_schema(
          chapter_id: { type: 'string', nullable: true },
          chapter_label: { type: 'string' },
          img_url: { type: 'string', nullable: true },
          date: { type: 'string', nullable: true }
        ),
        Pagination: object_schema(
          page: { type: 'integer' },
          limit: { type: 'integer', nullable: true },
          next_page: { type: 'integer', nullable: true },
          prev_page: { type: 'integer', nullable: true },
          has_next_page: { type: 'boolean' },
          total_pages: { type: 'integer', nullable: true }
        ),
        Home: object_schema(
          spotlight: array_schema(schema_ref('ComicSummary')),
          popular: array_schema(schema_ref('ComicSummary')),
          staff_picks: array_schema(schema_ref('ComicSummary')),
          latest_updates: array_schema(schema_ref('LatestUpdate')),
          novels: array_schema(schema_ref('ComicSummary'))
        ),
        LatestUpdate: object_schema(
          id: { type: 'string' },
          title: { type: 'string' },
          img_url: { type: 'string', nullable: true },
          language: { type: 'string', nullable: true },
          chapter_id: { type: 'string' },
          chapter_title: { type: 'string' },
          chapter_date: { type: 'string', nullable: true }
        ),
        Browse: object_schema(
          count: { type: 'integer' },
          comics: array_schema(schema_ref('ComicSummary')),
          pagination: schema_ref('Pagination')
        ),
        Search: object_schema(
          count: { type: 'integer' },
          total_count: { type: 'integer' },
          results: array_schema(schema_ref('ComicSummary')),
          pagination: schema_ref('Pagination'),
          filters: object_schema(
            status: { type: 'string', nullable: true },
            genre: { type: 'string', nullable: true }
          )
        ),
        Series: object_schema(
          id: { type: 'string' },
          title: { type: 'string' },
          img_url: { type: 'string', nullable: true },
          alt_titles: array_schema({ type: 'string' }),
          authors: array_schema({ type: 'string' }),
          artists: array_schema({ type: 'string' }),
          genres: array_schema({ type: 'string' }),
          status: { type: 'string', nullable: true },
          synopsis: { type: 'string', nullable: true },
          chapters: array_schema(schema_ref('Chapter'))
        ),
        Reader: object_schema(
          series_id: { type: 'string' },
          chapter_id: { type: 'string' },
          next_chapter_id: { type: 'string', nullable: true },
          prev_chapter_id: { type: 'string', nullable: true },
          title: { type: 'string' },
          count: { type: 'integer' },
          img_srcs: array_schema({ type: 'string' })
        ),
        CacheHealth: object_schema(
          cache: schema_ref('CacheStats'),
          checked_at: { type: 'string', format: 'date-time' }
        ),
        CacheClear: object_schema(
          cache: object_schema(
            cleared: { type: 'integer' },
            current: schema_ref('CacheStats')
          ),
          checked_at: { type: 'string', format: 'date-time' }
        ),
        CacheStats: object_schema(
          backend: { type: 'string', enum: %w[memory redis] },
          count: { type: 'integer' },
          default_ttl_seconds: { type: 'integer' },
          keys: array_schema(
            object_schema(
              key: { type: 'string' },
              expires_in_seconds: { type: 'integer' }
            )
          )
        ),
        ScraperHealth: object_schema(
          origin: { type: 'string' },
          reachable: { type: 'boolean' },
          status_code: { type: 'integer', nullable: true },
          next_data_present: { type: 'boolean' },
          latest_entries_present: { type: 'boolean' },
          latest_updates_count: { type: 'integer' },
          latest_chapters_count: { type: 'integer' },
          sample_release_date_present: { type: 'boolean' },
          checked_at: { type: 'string', format: 'date-time' }
        ),
        MetricsHealth: object_schema(
          metrics: object_schema(
            started_at: { type: 'string', format: 'date-time' },
            counters: { type: 'object', additionalProperties: { type: 'integer' } },
            timings: { type: 'object', additionalProperties: schema_ref('Timing') }
          ),
          checked_at: { type: 'string', format: 'date-time' }
        ),
        Timing: object_schema(
          count: { type: 'integer' },
          average_ms: { type: 'number' },
          max_ms: { type: 'number' }
        ),
        Index: object_schema(
          message: { type: 'string' },
          apiStatus: { type: 'boolean' },
          serverStatus: { type: 'string' },
          features: array_schema({ type: 'string' }),
          cache: object_schema(
            ttl_seconds: { type: 'integer' },
            endpoints: array_schema({ type: 'string' })
          ),
          endpoints: array_schema(
            object_schema(
              method: { type: 'string' },
              path: { type: 'string' },
              description: { type: 'string' }
            )
          )
        )
      }
    }
  end
  private_class_method :components

  def self.object_schema(properties = {})
    {
      type: 'object',
      properties: properties
    }
  end
  private_class_method :object_schema

  def self.array_schema(items)
    {
      type: 'array',
      items: items
    }
  end
  private_class_method :array_schema
end

# rubocop:enable Metrics/ClassLength
