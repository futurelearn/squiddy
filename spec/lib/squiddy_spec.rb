require 'spec_helper'
require 'rest-client'

require_relative '../../lib/squiddy'

RSpec.describe Squiddy::TrelloPullRequest do
  subject { described_class }

  let(:event) { double(Squiddy::Event) }
  let(:pull_request) { double(Squiddy::PullRequest) }
  let(:trello_checklist) { double(Squiddy::TrelloChecklist) }
  let(:trello_card) { "https://trello.com/c/12345678" }
  let(:pr_url) { "https://github.com/test/repository/pull/1" }

  before do
    allow(Squiddy::Event).to receive(:new).and_return(event)
    allow(Squiddy::PullRequest).to receive(:new).and_return(pull_request)
    allow(Squiddy::TrelloChecklist).to receive(:new).and_return(trello_checklist)

    allow(event).to receive(:type).and_return("pull_request")
    allow(event).to receive(:repository).and_return("test/repository")
    allow(event).to receive(:pull_request_number).and_return(1)

    allow(pull_request).to receive(:url).and_return(pr_url)

    allow(trello_checklist).to receive(:add_item).with(pr_url)
    allow(trello_checklist).to receive(:create_checklist)
    allow(trello_checklist).to receive(:mark_item_as_complete).with(pr_url).and_return(true)
  end

  context 'when the event is not a pull request' do
    before do
      allow(event).to receive(:type).and_return("push")
    end

    it 'does nothing' do
      expect(subject.run).to eq(nil)
    end
  end

  context 'a pull request is opened' do
    before do
      allow(pull_request).to receive(:open?).and_return(true)
      allow(pull_request).to receive(:closed?).and_return(false)
    end

    context 'with a link to a Trello card' do
      before do
        allow(pull_request).to receive(:body_regex).and_return(trello_card)
      end

      context 'when a checklist already exists' do
        before do
          allow(trello_checklist).to receive(:item_exist?).and_return(false)
          allow(trello_checklist).to receive(:checklist_exist?).and_return(true)
        end

        it 'adds an item to a checklist' do
          subject.run
          expect(trello_checklist).to have_received(:add_item).with(pr_url)
        end
      end

      context 'when a checklist does not exist' do
        before do
          allow(trello_checklist).to receive(:item_exist?).and_return(false)
          allow(trello_checklist).to receive(:checklist_exist?).and_return(false)
        end

        it 'creates a checklist' do
          subject.run
          expect(trello_checklist).to have_received(:create_checklist)
        end

        it 'adds an item to a checklist' do
          subject.run
          expect(trello_checklist).to have_received(:add_item).with(pr_url)
        end
      end

      context 'when the item already exists' do
        before do
          allow(trello_checklist).to receive(:item_exist?).and_return(true)
          allow(trello_checklist).to receive(:checklist_exist?).and_return(true)
        end

        it 'does nothing' do
          subject.run
          expect(trello_checklist).to_not have_received(:add_item)
        end
      end

      context 'when the checklist does not exist' do
        before do
          allow(trello_checklist).to receive(:add_item).and_raise(Squiddy::TrelloChecklist::ChecklistNotFound)
          allow(trello_checklist).to receive(:checklist_exist?).and_return(false)
          allow(trello_checklist).to receive(:item_exist?).and_raise(Squiddy::TrelloChecklist::ChecklistNotFound)
          allow(trello_checklist).to receive(:mark_item_as_complete).and_raise(Squiddy::TrelloChecklist::ChecklistNotFound)
        end

        it 'rescues an error' do
          expect(subject.run).to eq("Squiddy::TrelloChecklist::ChecklistNotFound")
        end
      end

      context 'when the card does not exist' do
        before do
          allow(Squiddy::TrelloChecklist).to receive(:new).with(trello_card).and_raise(Squiddy::TrelloChecklist::CardNotFound)
        end

        it 'raises an error' do
          expect { subject.run }.to raise_error(Squiddy::TrelloChecklist::CardNotFound)
        end
      end
    end

    context 'with no link to a Trello card' do
      before do
        allow(pull_request).to receive(:body_regex).and_return(nil)
      end

      it 'does nothing' do
        subject.run
        expect(trello_checklist).to_not have_received(:add_item).with(pr_url)
      end
    end
  end

  context 'a pull request is closed' do
    before do
      allow(pull_request).to receive(:open?).and_return(false)
      allow(pull_request).to receive(:closed?).and_return(true)
    end

    context 'with a link to a Trello card' do
      before do
        allow(pull_request).to receive(:body_regex).and_return(trello_card)
      end

      context 'when the item exists' do
        before do
          allow(trello_checklist).to receive(:item_exist?).and_return(true)
        end

        it 'gets marked as complete' do
          subject.run
          expect(trello_checklist).to have_received(:mark_item_as_complete).with(pr_url)
        end
      end

      context 'when the item does not exist' do
        before do
          allow(trello_checklist).to receive(:item_exist?).and_return(false)
        end

        it 'does nothing' do
          subject.run
          expect(trello_checklist).to_not have_received(:mark_item_as_complete)
        end
      end

      context 'when the checklist does not exist' do
        before do
          allow(trello_checklist).to receive(:add_item).and_raise(Squiddy::TrelloChecklist::ChecklistNotFound)
          allow(trello_checklist).to receive(:item_exist?).and_raise(Squiddy::TrelloChecklist::ChecklistNotFound)
          allow(trello_checklist).to receive(:mark_item_as_complete).and_raise(Squiddy::TrelloChecklist::ChecklistNotFound)
        end

        it 'rescues an error' do
          expect(subject.run).to eq("Squiddy::TrelloChecklist::ChecklistNotFound")
        end
      end

      context 'when the card does not exist' do
        before do
          allow(Squiddy::TrelloChecklist).to receive(:new).and_raise(Squiddy::TrelloChecklist::CardNotFound)
        end

        it 'raises an error' do
          expect { subject.run }.to raise_error(Squiddy::TrelloChecklist::CardNotFound)
        end
      end
    end

    context 'with no link to a Trello card' do
      before do
        allow(pull_request).to receive(:body_regex).and_return(nil)
      end

      it 'does nothing' do
        subject.run
        expect(trello_checklist).to_not have_received(:mark_item_as_complete)
      end
    end
  end
end
