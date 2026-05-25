# frozen_string_literal: true

require 'httparty'
require_relative 'observability'

module HttpClient
  DEFAULT_TIMEOUT = 10
  DEFAULT_RETRIES = 1

  module_function

  def get(url, timeout: DEFAULT_TIMEOUT, retries: DEFAULT_RETRIES)
    attempts = 0

    begin
      attempts += 1
      Observability.measure('http_client.duration') do
        response = HTTParty.get(url, timeout: timeout)
        Observability.increment('http_client.requests')
        Observability.increment("http_client.status.#{response.code}")
        Observability.increment('http_client.failures') unless response.code.to_i.between?(200, 399)
        response
      end
    rescue StandardError
      Observability.increment('http_client.exceptions')
      retry if attempts <= retries

      raise
    end
  end
end
