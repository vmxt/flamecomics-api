# frozen_string_literal: true

require 'spec_helper'
require_relative '../../controllers/search'
require_relative '../../controllers/browse'

RSpec.describe SearchController do
  describe '.search_by_title' do
    let(:mock_comics) do
      {
        comics: [
          { title: "Regressing as the Reincarnated Bastard of the Sword Clan", id: 1 },
          { title: "Omniscient Reader's Viewpoint", id: 2 },
          { title: "Leveling With The Gods", id: 3 },
          { title: "The Ancient Sovereign of Eternity", id: 4 },
          { title: "Heavenly Demon Cultivation Simulation", id: 5 },
          { title: "Dungeon Reset", id: 6 },
          { title: "Tyrant of the Tower Defense Game", id: 7 },
          { title: "I Used to be a Boss", id: 8 },
          { title: "IRL Quest", id: 9 },
          { title: "The 31st Piece Overturns the Board", id: 10 },
          { title: "The Third Prince of the Fallen Kingdom has Regressed", id: 11 },
          { title: "Return of The Frozen Player", id: 12 },
          { title: "Solo Leveling: Ragnarok", id: 13 },
          { title: "A Regressor's Tale of Cultivation", id: 14 },
          { title: "The Chaotic God of Extraordinary Strength", id: 15 },
          { title: "Wild West Murim", id: 16 }
        ]
      }
    end

    context 'when title parameter is missing or empty' do
      it 'returns an error hash when title is nil' do
        result = described_class.search_by_title(nil)
        expect(result[:error]).to eq('Missing title parameter')
      end

      it 'returns an error hash when title is empty' do
        result = described_class.search_by_title('   ')
        expect(result[:error]).to eq('Missing title parameter')
      end
    end

    context 'when BrowseController returns an error' do
      it 'returns the error hash' do
        allow(BrowseController).to receive(:fetch_series).and_return({ error: 'Failed to fetch series' })

        result = described_class.search_by_title('Omniscient Reader')
        expect(result[:error]).to eq('Failed to fetch series')
      end
    end

    context 'when BrowseController returns valid data' do
      before do
        allow(BrowseController).to receive(:fetch_series).and_return(mock_comics)
      end

      it 'finds an exact title match' do
        result = described_class.search_by_title('Return of The Frozen Player')
        expect(result[:count]).to eq(1)
        expect(result[:results].first[:title]).to eq('Return of The Frozen Player')
      end

      it 'finds a match ignoring case' do
        result = described_class.search_by_title("omniscient reader's viewpoint")
        expect(result[:count]).to eq(1)
        expect(result[:results].first[:title]).to eq("Omniscient Reader's Viewpoint")
      end

      it 'finds a partial match' do
        result = described_class.search_by_title('Leveling')
        titles = result[:results].map { |r| r[:title] }
        expect(result[:count]).to eq(2)
        expect(titles).to include('Leveling With The Gods', 'Solo Leveling: Ragnarok')
      end

      it 'matches even when punctuation differs' do
        result = described_class.search_by_title('Solo Leveling Ragnarok')
        expect(result[:count]).to eq(1)
        expect(result[:results].first[:title]).to eq('Solo Leveling: Ragnarok')
      end

      it 'matches titles containing multiple spaces or symbols' do
        result = described_class.search_by_title('The 31st Piece Overturns   the Board!!!')
        expect(result[:count]).to eq(1)
        expect(result[:results].first[:title]).to eq('The 31st Piece Overturns the Board')
      end

      it 'returns multiple matches for similar terms' do
        result = described_class.search_by_title('Regress')
        titles = result[:results].map { |r| r[:title] }
        expect(result[:count]).to be > 1
        expect(titles).to include(
          'Regressing as the Reincarnated Bastard of the Sword Clan',
          'The Third Prince of the Fallen Kingdom has Regressed',
          "A Regressor's Tale of Cultivation"
        )
      end
    end

    context 'when an unexpected error occurs' do
      it 'returns an error hash with message' do
        allow(BrowseController).to receive(:fetch_series).and_raise(StandardError.new('Unexpected failure'))

        result = described_class.search_by_title('Dungeon')
        expect(result[:error]).to match(/Error performing search: Unexpected failure/)
      end
    end
  end
end
