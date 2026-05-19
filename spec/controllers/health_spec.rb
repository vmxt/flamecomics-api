# frozen_string_literal: true

require 'spec_helper'
require_relative '../../controllers/health'

RSpec.describe HealthController do
  describe '.scrapers' do
    it 'reports Next.js latest entry scraper status' do
      html = File.read(File.expand_path('../fixtures/home_next_data.html', __dir__))
      allow(HTTParty).to receive(:get).and_return(double(code: 200, body: html))

      result = described_class.scrapers

      expect(result).to include(
        reachable: true,
        status_code: 200,
        next_data_present: true,
        latest_entries_present: true,
        latest_updates_count: 1,
        latest_chapters_count: 2,
        sample_release_date_present: true
      )
    end
  end
end
