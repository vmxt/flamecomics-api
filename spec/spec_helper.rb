# frozen_string_literal: true

# -----------------------------------------------------------------------------
# RSpec configuration for FlamecomicsAPI (Roda)
# -----------------------------------------------------------------------------
# This file sets up RSpec for your API server with:
#  - Rack::Test for HTTP request simulation
#  - Colorized CLI output
#  - Documentation-style formatting
#  - Randomized test order
# -----------------------------------------------------------------------------

require 'rack/test'
require 'rspec'
require 'vcr'
require 'webmock/rspec'
require_relative '../app'
require_relative '../utils/response_cache'

ENV['RACK_ENV'] = 'test'

WebMock.disable_net_connect!(allow_localhost: true)

VCR.configure do |config|
  config.cassette_library_dir = 'spec/cassettes'
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

RSpec.configure do |config|
  include Rack::Test::Methods

  def app
    FlamecomicsAPI.app
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # -----------------------------------------------------------------------------
  # CLI OUTPUT SETTINGS
  # -----------------------------------------------------------------------------

  # Always show full, readable output in the CLI (no dots)
  config.default_formatter = "doc"

  # Enable colorized output for better visibility
  config.color = true
  config.tty = true

  # Disable persistence file — no examples.txt will be created
  # (you can re-enable if you want --only-failures functionality)
  # config.example_status_persistence_file_path = "spec/examples.txt"

  # -----------------------------------------------------------------------------
  # Test order and randomization
  # -----------------------------------------------------------------------------
  config.order = :random
  Kernel.srand config.seed

  # Allow focusing on specific specs with `fit` / `fdescribe`
  config.filter_run_when_matching :focus

  config.profile_examples = 5

  config.after do
    ResponseCache.clear
  end
end
