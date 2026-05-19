# frozen_string_literal: true

require 'json'
require_relative 'error_response'

class RateLimiter
  WINDOW_SECONDS = 60
  MAX_REQUESTS = 120

  def initialize(app, max_requests: MAX_REQUESTS, window_seconds: WINDOW_SECONDS)
    @app = app
    @max_requests = max_requests
    @window_seconds = window_seconds
    @requests = {}
  end

  def call(env)
    key = env['REMOTE_ADDR'] || 'unknown'
    now = Time.now.to_i
    entry = current_entry(key, now)

    return rate_limited_response(entry) if entry[:count] > @max_requests

    status, headers, body = @app.call(env)
    headers['X-RateLimit-Limit'] = @max_requests.to_s
    headers['X-RateLimit-Remaining'] = remaining(entry).to_s
    headers['X-RateLimit-Reset'] = entry[:reset_at].to_s

    [status, headers, body]
  end

  private

  def current_entry(key, now)
    entry = @requests[key]

    if entry.nil? || entry[:reset_at] <= now
      entry = { count: 0, reset_at: now + @window_seconds }
      @requests[key] = entry
    end

    entry[:count] += 1
    entry
  end

  def remaining(entry)
    [@max_requests - entry[:count], 0].max
  end

  def rate_limited_response(entry)
    body = ErrorResponse.build(
      'Rate limit exceeded',
      code: 'rate_limit_exceeded',
      source: 'rate_limiter'
    )

    [
      429,
      {
        'Content-Type' => 'application/json',
        'Retry-After' => [entry[:reset_at] - Time.now.to_i, 0].max.to_s,
        'X-RateLimit-Limit' => @max_requests.to_s,
        'X-RateLimit-Remaining' => '0',
        'X-RateLimit-Reset' => entry[:reset_at].to_s
      },
      [JSON.generate(body)]
    ]
  end
end
