require 'spec_helper'

require 'hashie/mash'
require_relative '../../../actions/bubble_merge/git_client'

RSpec.describe Squiddy::GitClient do
  subject { described_class.new }
  let(:event) {
    {
      'comment': {
        'user': {
          'login': 'test-user',
          'body': 'test-body'
        }
      },
      'issue': {
        'number': 'test-pr-number'
      },
      'repository': {
        'full_name': 'test-user/test-repo'
      }
    }.to_json
  }
  let(:pull_request) {
    Hashie::Mash.new({
      base: { ref: 'test-base-branch' },
      head: { ref: 'test-branch', sha: '1234' }
    })
  }
  let(:branch) {
    Hashie::Mash.new({
      commit: { sha: '1234' },
    })
  }
  let(:pull_merged?) { false }
  let(:octokit_client) {
    instance_double(
      'Octokit::Client',
      merge_pull_request: nil,
      delete_branch: nil,
      add_comment: nil,
      pull_merged?: pull_merged?
    )
  }
  let(:repository) { double("Repository", delete_branch_on_merge: false) }

  before do
    stub_const('ENV', 'GITHUB_EVENT' => event, 'GITHUB_TOKEN' => 'token')
    allow(Octokit::Client).to receive(:new).and_return(octokit_client)
    allow(octokit_client).to receive(:pull_request).with('test-user/test-repo', 'test-pr-number').and_return(pull_request)
    allow(octokit_client).to receive(:branch).with('test-user/test-repo', 'test-branch').and_return(branch)
    allow(octokit_client).to receive(:repository).with('test-user/test-repo').and_return(repository)
  end

  around do |example|
    begin
      old_stdout = $stdout
      $stdout = StringIO.new(String.new, 'w')
      example.call
    ensure
      $stdout = old_stdout
    end
  end

  context '#bubble_merge' do
    let(:commit_message) {
      <<~MESSAGE
        Merge branch 'test-branch' into test-base-branch

        Squiddy-bot has merged the branch test-branch
        into test-base-branch after rebase as requested by test-user
        in PR #test-pr-number.

        Further details are listed below.

        Squiddy out.

      MESSAGE
    }

    it 'merges successfully' do
      expect(octokit_client).to receive(:merge_pull_request).with(
        'test-user/test-repo',
        'test-pr-number',
        commit_message,
        {
          merge_method: 'merge',
          sha: '1234'
        }
      )
      subject.bubble_merge
    end

    it 'deletes the branch' do
      expect(octokit_client).to receive(:delete_branch)
      subject.bubble_merge
    end

    context 'when an error occurs' do
      let(:error_message) {
        <<~MESSAGE
          Oh no! Auto-merging could not be performed. Please fix all merge conflicts and try again.

          #### Error message:
          Octokit::Conflict
        MESSAGE
      }

      before do
        allow(octokit_client).to receive(:merge_pull_request).and_raise(Octokit::Conflict.new)
      end

      it 'prints an error message' do
        expect(octokit_client).to receive(:add_comment).with('test-user/test-repo', 'test-pr-number', error_message)
        subject.bubble_merge
      end

      it 'does not delete the branch' do
        expect(octokit_client).not_to receive(:delete_branch)
        subject.bubble_merge
      end
    end

    context 'when the PR has already been merged' do
      before do
        allow(octokit_client).to receive(:pull_merged?).and_return(true)
      end

      it 'does not attempt to merge again' do
        expect(octokit_client).not_to receive(:merge_pull_request)
        subject.bubble_merge
      end

      it 'does not delete the branch' do
        expect(octokit_client).not_to receive(:delete_branch)
        subject.bubble_merge
      end
    end

    context 'when the PR branch and PR are out of sync' do
      let(:pull_request_head) { double(:pull_request_head, ref: 'test-branch') }
      let(:pull_request) {
        Hashie::Mash.new({
          base: { ref: 'test-base-branch' },
          head: pull_request_head,
        })
      }
      let(:branch) {
        Hashie::Mash.new({
          commit: { sha: '1234' },
        })
      }

      before do
        allow(subject).to receive(:sleep)
      end

      it 'waits 5 times and then fails' do
        allow(pull_request_head).to receive(:sha).and_return('5678')

        expect {
          subject.bubble_merge
        }.to raise_error(/PR HEAD 5678 did not match test-branch HEAD 1234/)
        expect(subject).to have_received(:sleep).exactly(5).times
      end

      it 'recovers if the PR updates to match the branch' do
        allow(pull_request_head).to receive(:sha).and_return('5678', '1234')

        subject.bubble_merge

        expect(subject).to have_received(:sleep).once
      end
    end

    context 'when the repository auto deletes branches on merge' do
      let(:repository) { double(delete_branch_on_merge: true) }

      it 'skips deleting the branch' do
        expect(octokit_client).not_to receive(:delete_branch)
        subject.bubble_merge
      end
    end
  end
end
