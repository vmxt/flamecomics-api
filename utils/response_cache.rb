# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength

require 'json'
require_relative 'observability'

module ResponseCache
  DEFAULT_TTL = 180
  REDIS_PREFIX = 'flamecomics-api:cache:'

  @store = {}
  @redis = nil

  begin
    require 'connection_pool'
    require 'redis'
  rescue LoadError
    nil
  end

  module_function

  def fetch(key, ttl: DEFAULT_TTL)
    if redis_enabled?
      cached = redis_get(key)
      if cached
        Observability.increment('cache.hits')
        return cached
      end

      Observability.increment('cache.misses')
      value = yield
      redis_set(key, value, ttl)
      return value
    end

    now = Time.now
    cached = @store[key]
    if cached && cached[:expires_at] > now
      Observability.increment('cache.hits')
      return cached[:value]
    end

    Observability.increment('cache.misses')
    value = yield
    @store[key] = { value: value, expires_at: now + ttl }
    value
  end

  def stats
    return redis_stats if redis_enabled?

    now = Time.now
    prune_expired(now)

    {
      backend: 'memory',
      count: @store.size,
      default_ttl_seconds: DEFAULT_TTL,
      keys: @store.map do |key, entry|
        {
          key: key,
          expires_in_seconds: [(entry[:expires_at] - now).ceil, 0].max
        }
      end
    }
  end

  def clear
    if redis_enabled?
      cleared = redis_keys.size
      redis.with { |client| redis_keys.each { |key| client.del(key) } }
      return cleared
    end

    cleared = @store.size
    @store.clear
    cleared
  end

  def prune_expired(now = Time.now)
    @store.delete_if { |_key, entry| entry[:expires_at] <= now }
  end

  def redis_enabled?
    ENV.fetch('REDIS_URL', nil) && defined?(ConnectionPool) && defined?(Redis)
  end

  def redis
    @redis ||= ConnectionPool.new(size: 5, timeout: 5) { Redis.new(url: ENV.fetch('REDIS_URL')) }
  end

  def redis_key(key)
    "#{REDIS_PREFIX}#{key}"
  end

  def redis_get(key)
    payload = redis.with { |client| client.get(redis_key(key)) }
    return unless payload

    JSON.parse(payload, symbolize_names: true)
  rescue StandardError
    Observability.increment('cache.redis_errors')
    nil
  end

  def redis_set(key, value, ttl)
    redis.with { |client| client.set(redis_key(key), JSON.generate(value), ex: ttl) }
  rescue StandardError
    Observability.increment('cache.redis_errors')
  end

  def redis_keys
    redis.with { |client| client.keys("#{REDIS_PREFIX}*") }
  rescue StandardError
    Observability.increment('cache.redis_errors')
    []
  end

  def redis_stats
    keys = redis_keys
    {
      backend: 'redis',
      count: keys.size,
      default_ttl_seconds: DEFAULT_TTL,
      keys: keys.map do |key|
        ttl = redis.with { |client| client.ttl(key) }
        {
          key: key.delete_prefix(REDIS_PREFIX),
          expires_in_seconds: [ttl.to_i, 0].max
        }
      end
    }
  end
end

# rubocop:enable Metrics/ModuleLength
