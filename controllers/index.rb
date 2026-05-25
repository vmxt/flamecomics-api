# frozen_string_literal: true

class IndexController
  def self.fetch
    {
      message: 'Flamecomics Manga scraper',
      apiStatus: true,
      serverStatus: 'ONLINE',
      features: [
        'Latest updates from embedded Next.js data',
        'Scraper health diagnostics',
        'Short TTL response caching',
        'Cache-Control headers on cached routes',
        'In-memory cache stats',
        'Rate limiting',
        'Optional Redis cache backend',
        'Request and scraper metrics',
        'Request timeouts with retry',
        'Structured error responses',
        'Versioned /v1 API aliases',
        'OpenAPI documentation',
        'Normalized chapter fields'
      ],
      cache: {
        ttl_seconds: 180,
        endpoints: ['/home', '/browse', '/series/:id']
      },
      endpoints: endpoints
    }
  end

  def self.endpoints
    [
      endpoint('GET', '/', 'API index and feature list'),
      endpoint('GET', '/openapi.json', 'OpenAPI document'),
      endpoint('GET', '/health/scrapers', 'Check FlameComics reachability and scraper data shape'),
      endpoint('GET', '/health/cache', 'Inspect in-memory cache stats'),
      endpoint('DELETE', '/health/cache', 'Clear cached scraper responses'),
      endpoint('GET', '/health/metrics', 'Inspect request, cache, and upstream metrics'),
      endpoint('GET', '/home', 'Home page sections, including latest updates'),
      endpoint('GET', '/browse', 'Browse series; accepts FlameComics query parameters'),
      endpoint('GET', '/search?title=:title', 'Search browse results by title'),
      endpoint('GET', '/series/:id', 'Series details and normalized chapters'),
      endpoint('GET', '/series/:id/:chapter_id', 'Chapter pages/images'),
      endpoint('GET', '/random', 'Redirect to a random valid series'),
      endpoint('GET', '/v1/*', 'Versioned aliases for API endpoints')
    ]
  end
  private_class_method :endpoints

  def self.endpoint(method, path, description)
    {
      method: method,
      path: path,
      description: description
    }
  end
  private_class_method :endpoint
end
