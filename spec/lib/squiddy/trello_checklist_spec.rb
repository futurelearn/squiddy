require 'spec_helper'

require_relative '../../../lib/squiddy/trello_checklist'

RSpec.describe Squiddy::TrelloChecklist do
  subject { described_class.new("https://trello.com/c/1234546789") }

  context 'the checklist does not exist' do
    describe '#create_checklist' do
      it 'creates a checklist on the card and returns true' do
        expect(subject.create).to eq(true)
      end
    end

    describe '#checklist_exist?' do
      it 'returns false' do
        expect(subject.exist?).to eq(false)
      end
    end

    describe '#add_item' do
      it 'returns true when the item is added' do
        expect(subject.add_item('test')).to eq(true)
      end
    end

    describe '#mark_item_as_complete' do
      it 'returns true when the item is marked as complete' do
        expect(subject.mark_item_as_complete('test')).to eq(true)
      end
    end
  end

  context 'the checklist exists' do
    describe '#create_checklist' do
      it 'returns false' do
        expect(subject.create).to eq(false)
      end
    end

    describe '#checklist_exist?' do
      it 'returns true' do
        expect(subject.exist?).to eq(true)
      end
    end

    describe '#add_item' do
      it 'returns true when the item is added' do
        expect(subject.add_item('test')).to eq(true)
      end
    end

    describe '#mark_item_as_complete' do
      it 'returns true when the item is marked as complete' do
        expect(subject.mark_item_as_complete('test')).to eq(true)
      end
    end
  end

  describe '#card_id_from_url' do
    let(:good_url) { "https://trello.com/c/1234abcd/good-card" }
    let(:bad_url) { "https://trello.com/b/1234abcd/bad-board" }
    let(:non_existent_url) { "https://trello.com/c/12345678/bad-card" }
    let(:non_url) { "some-string" }

    it 'returns the card ID from a given Trello card URL' do
      expect(subject.card_id_from_url(good_url)).to eq('1234abcd')
    end

    it 'returns an error when given a non-card URL' do
      expect { subject.card_id_from_url(bad_url) }.to raise_error(Squiddy::TrelloChecklist::CardNotFound)
    end

    it 'returns an error when not a URL' do
      expect { subject.card_id_from_url(non_url) }.to raise_error(StandardError)
    end
  end
end
