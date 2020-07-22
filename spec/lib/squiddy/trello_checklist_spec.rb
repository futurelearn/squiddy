require 'spec_helper'
require 'rest-client'

require_relative '../../../lib/squiddy/trello_checklist'

RSpec.describe Squiddy::TrelloChecklist do
  subject { described_class.new("https://trello.com/c/1234546789") }

  context 'the checklist does not exist' do
    let(:trello_checklist) { instance_double(Trello::Checklist) }
    let(:trello_card) { instance_double(Trello::Card, checklists: [], id: 'a-long-card-id') }
    let(:client) { double(Trello::Client, find: trello_card) }

    before do
      allow(Trello::Client).to receive(:new).and_return(client)
      allow(client).to receive(:find).with(:card, "https://trello.com/c/1234546789").and_return(trello_card)
      allow(client).to receive(:create).with(:checklist, name: "Pull Requests", "idCard" => "a-long-card-id")
        .and_return(trello_checklist)
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

    describe '#add_item' do
      it 'raises an error' do
        expect { subject.add_item('test') }.to raise_error(Squiddy::TrelloChecklist::ChecklistNotFound)
      end
    end

    describe '#mark_item_as_complete' do
      it 'raises an error' do
        expect { subject.add_item('test') }.to raise_error(Squiddy::TrelloChecklist::ChecklistNotFound)
      end
    end
  end

  context 'the checklist exists' do
    let(:trello_item) { instance_double(Trello::Item, name: "test", id: "1234") }
    let(:rest_response) { instance_double(RestClient::Response) }
    let(:trello_checklist) { instance_double(Trello::Checklist, name: "Pull Requests", add_item: rest_response) }
    let(:trello_card) { instance_double(Trello::Card, checklists: [trello_checklist], id: 'a-long-card-id') }
    let(:client) { double(Trello::Client, find: trello_card) }

    before do
      allow(Trello::Client).to receive(:new).and_return(client)
      allow(client).to receive(:find).with(:card, "https://trello.com/c/1234546789").and_return(trello_card)
      allow(client).to receive(:create).with(:checklist, name: "Pull Requests", "idCard" => "a-long-card-id")
        .and_return(trello_checklist)
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
    let(:non_url) { "some-string" }

    it 'returns the card ID from a given Trello card URL' do
      expect(Squiddy::TrelloChecklist.new(good_url).card_id_from_url).to eq('1234abcd')
    end

    it 'returns an error when given a non-card URL' do
      expect { Squiddy::TrelloChecklist.new(bad_url).card_id_from_url }.to raise_error(Squiddy::TrelloChecklist::CardNotFound)
    end

    it 'returns an error when not a URL' do
      expect { Squiddy::TrelloChecklist.new(non_url).card_id_from_url }.to raise_error(StandardError)
    end
  end
end
