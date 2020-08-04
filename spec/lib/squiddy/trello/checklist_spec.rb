require 'spec_helper'
require 'rest-client'

require_relative '../../../../lib/squiddy/trello'

RSpec.describe Squiddy::Trello::Checklist do
  subject { described_class.new("https://trello.com/c/1234546789") }

  context 'the checklist does not exist' do
    let(:unrelated_trello_checklist) { instance_double(Trello::Checklist, name: "Some other checklist") }
    let(:trello_checklist) { instance_double(Trello::Checklist) }
    let(:trello_card) { instance_double(Trello::Card, checklists: [unrelated_trello_checklist], id: 'a-long-card-id') }
    let(:trello_checklist) { instance_double(::Trello::Checklist) }
    let(:trello_card) { instance_double(::Trello::Card, checklists: [], id: 'a-long-card-id') }

    before do
      allow(Trello::Card).to receive(:find).and_return(trello_card)
      allow(trello_card).to receive(:create_new_checklist).and_return(trello_checklist)
      allow(trello_checklist).to receive(:add_item).and_return(200)
    end

    describe '#create_checklist' do
      it 'creates a checklist on the card and return the checklist object' do
        expect(subject.create_checklist).to eq(trello_checklist)
      end
    end

    describe '#checklist_exist?' do
      it 'returns false' do
        expect(subject.checklist_exist?).to eq(false)
      end
    end

    describe '#item_exist?' do
      it 'raises an error' do
        expect { subject.item_exist?('test') }.to raise_error(Squiddy::Trello::Checklist::ChecklistNotFound)
      end
    end

    describe '#add_item' do
      it 'raises an error' do
        expect { subject.add_item('test') }.to raise_error(Squiddy::Trello::Checklist::ChecklistNotFound)
      end
    end

    describe '#mark_item_as_complete' do
      it 'raises an error' do
        expect { subject.add_item('test') }.to raise_error(Squiddy::Trello::Checklist::ChecklistNotFound)
      end
    end
  end

  context 'the checklist exists' do
    let(:trello_item) { instance_double(Trello::Item, name: "test", id: "1234") }
    let(:rest_response) { instance_double(RestClient::Response) }
    let(:unrelated_trello_checklist) { instance_double(Trello::Checklist, name: "Some other checklist") }
    let(:trello_checklist) { instance_double(Trello::Checklist, name: "Pull Requests", add_item: rest_response) }
    let(:trello_card) { instance_double(::Trello::Card, checklists: [trello_checklist, unrelated_trello_checklist], id: 'a-long-card-id') }

    before do
      allow(Trello::Card).to receive(:find).and_return(trello_card)
      allow(trello_card).to receive(:create_new_checklist).and_return(trello_checklist)

      allow(trello_checklist).to receive(:add_item).and_return(rest_response)
      allow(trello_checklist).to receive(:items).and_return([trello_item])
      allow(trello_checklist).to receive(:update_item_state).and_return(trello_checklist)
      allow(trello_checklist).to receive(:save).and_return(trello_checklist)
      allow(rest_response).to receive(:code).and_return(200)
    end

    describe '#create_checklist' do
      it 'returns false' do
        expect(subject.create_checklist).to eq(trello_checklist)
      end
    end

    describe '#checklist_exist?' do
      it 'returns true' do
        expect(subject.checklist_exist?).to eq(true)
      end
    end

    describe '#item_exist?' do
      it 'returns true when the item exists' do
        expect(subject.item_exist?('test')).to eq(true)
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

    context 'the item does not exist' do
      before do
        allow(trello_checklist).to receive(:items).and_return([])
      end

      describe '#item_exist?' do
        it 'returns false' do
          expect(subject.item_exist?('test')).to eq(false)
        end
      end
    end
  end

  describe '#card_id_from_url' do
    let(:good_url) { "https://trello.com/c/1234abcd/good-card" }
    let(:bad_url) { "https://trello.com/b/1234abcd/bad-board" }
    let(:non_url) { "some-string" }

    it 'returns the card ID from a given Trello card URL' do
      expect(Squiddy::Trello::Checklist.new(good_url).card_id_from_url).to eq('1234abcd')
    end

    it 'returns an error when given a non-card URL' do
      expect { Squiddy::Trello::Checklist.new(bad_url).card_id_from_url }.to raise_error(Squiddy::Trello::Checklist::CardNotFound)
    end

    it 'returns an error when not a URL' do
      expect { Squiddy::Trello::Checklist.new(non_url).card_id_from_url }.to raise_error(StandardError)
    end
  end
end
