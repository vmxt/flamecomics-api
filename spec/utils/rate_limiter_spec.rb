# frozen_string_literal: true

require 'spec_helper'
require_relative '../../utils/rate_limiter'

RSpec.describe RateLimiter do
  it 'returns structured 429 responses after the request limit' do
    app = ->(_env) { [200, {}, ['ok']] }
    limiter = described_class.new(app, max_requests: 1, window_seconds: 60)
    env = { 'REMOTE_ADDR' => '127.0.0.1' }

    limiter.call(env)
    status, headers, body = limiter.call(env)

    parsed_body = JSON.parse(body.join)
    expect(status).to eq(429)
    expect(headers).to include('Retry-After', 'X-RateLimit-Limit')
    expect(parsed_body).to include(
      'error' => 'Rate limit exceeded',
      'code' => 'rate_limit_exceeded',
      'source' => 'rate_limiter'
    )
  end
end
