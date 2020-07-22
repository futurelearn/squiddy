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
end
