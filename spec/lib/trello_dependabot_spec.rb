require 'spec_helper'
require 'rest-client'

require_relative '../../lib/squiddy'

RSpec.describe Squiddy::TrelloDependabot do
  subject { described_class }

  let(:event) { double(Squiddy::Event) }
  let(:pull_request) { double(Squiddy::PullRequest) }
  let(:trello_card) { double(Trello::Card) }
  let(:trello_board) { double(Trello::Board) }
  let(:trello_label) { double(Trello::Label) }
  let(:pr_url) { "https://github.com/test/repository/pull/1" }
  let(:pr_body) { "Body text" }
  let(:pr_title) { "Title text" }

  before do
    allow(Squiddy::Event).to receive(:new).and_return(event)
    allow(Squiddy::PullRequest).to receive(:new).and_return(pull_request)

    allow(Trello::Board).to receive(:find).and_return(trello_board)
    allow(Trello::Card).to receive(:create).and_return(trello_card)

    allow(trello_board).to receive(:cards).and_return([trello_card])
    allow(trello_board).to receive(:labels).and_return([trello_label])

    allow(trello_card).to receive(:name).and_return("Title text")

    allow(event).to receive(:type).and_return("pull_request")
    allow(event).to receive(:repository).and_return("test/repository")
    allow(event).to receive(:pull_request_number).and_return(1)

    allow(pull_request).to receive(:url).and_return(pr_url)
    allow(pull_request).to receive(:body).and_return(pr_body)
    allow(pull_request).to receive(:title).and_return(pr_title)
    allow(pull_request).to receive(:labels).and_return(["dependabot"])
  end

  context 'when the event is not a pull request' do
    before do
      allow(event).to receive(:type).and_return("push")
    end

    it 'does nothing' do
      expect(subject.run(board_id: 1234, list_create_id: 1234, list_done_id: 5678, github_label: 'dependabot', pull_request_number: 1)).to eq(nil)
    end
  end

  context 'a pull request is opened' do
    before do
      allow(pull_request).to receive(:open?).and_return(true)
      allow(pull_request).to receive(:closed?).and_return(false)
    end

    context 'when it has a dependabot label' do
      context 'when the card exists' do
        it 'does nothing' do
          expect(subject.run(board_id: 1234, list_create_id: 1234, list_done_id: 5678, github_label: 'dependabot', pull_request_number: 1)).to eq(nil)
        end
      end

      context 'when the card does not exist' do
        before do
          allow(trello_board).to receive(:cards).and_return([])
          allow(trello_label).to receive(:name).and_return("Dependabot")
          allow(trello_label).to receive(:id).and_return("some-label-id")
        end

        it 'creates the card in the defined list' do
          subject.run(board_id: 1234, list_create_id: 1234, list_done_id: 5678, github_label: 'dependabot', pull_request_number: 1)
          expect(::Trello::Card).to have_received(:create).with(list_id: 1234, name: "Title text", desc: "Body text\n\nhttps://github.com/test/repository/pull/1", card_labels: ["some-label-id"], pos: "bottom")
        end
      end
    end

    context 'when it does not have a dependabot label' do
      it 'does nothing' do
          expect(subject.run(board_id: 1234, list_create_id: 1234, list_done_id: 5678, github_label: 'dependabot', pull_request_number: 1)).to eq(nil)
      end
    end
  end

  context 'a pull request is closed' do
    before do
      allow(pull_request).to receive(:open?).and_return(false)
      allow(pull_request).to receive(:closed?).and_return(true)

      allow(trello_card).to receive(:move_to_list)
    end

    context 'when it has a dependabot label' do
      context 'when the card exists' do
        it 'moves the card to the done list' do
          subject.run(board_id: 1234, list_create_id: 1234, list_done_id: 5678, github_label: 'dependabot', pull_request_number: 1)
          expect(trello_card).to have_received(:move_to_list).with(5678)
        end
      end

      context 'when the card does not exist' do
        it 'does nothing' do
          expect(subject.run(board_id: 1234, list_create_id: 1234, list_done_id: 5678, github_label: 'dependabot', pull_request_number: 1)).to eq(nil)
        end
      end
    end

    context 'when it does not have a dependabot label' do
      it 'does nothing' do
        expect(subject.run(board_id: 1234, list_create_id: 1234, list_done_id: 5678, github_label: 'dependabot', pull_request_number: 1)).to eq(nil)
      end
    end
  end
end
