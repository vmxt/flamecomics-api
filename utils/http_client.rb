# frozen_string_literal: true

require 'httparty'

module HttpClient
  DEFAULT_TIMEOUT = 10
  DEFAULT_RETRIES = 1

  module_function

  def get(url, timeout: DEFAULT_TIMEOUT, retries: DEFAULT_RETRIES)
    attempts = 0

    begin
      attempts += 1
      HTTParty.get(url, timeout: timeout)
    rescue StandardError
      retry if attempts <= retries

      raise
    end
  end
end
