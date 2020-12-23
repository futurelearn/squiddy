require 'spec_helper'

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
  let(:pr_data) { { base: { ref: 'test-base-branch' }, head: { ref: 'test-branch' } } }
  let(:octokit_client) { instance_double('Octokit::Client', merge: nil, delete_branch: nil, add_comment: nil) }
  let(:head_commit_status) do
    {
      total_count: '1',
      check_suites: [
        {
          id: '1',
          status: 'completed',
          conclusion: 'success'
        }
      ]
    }
  end

  before do
    stub_const('ENV', 'GITHUB_EVENT' => event, 'GITHUB_TOKEN' => 'token')
    allow(Octokit::Client).to receive(:new).and_return(octokit_client)
    allow(octokit_client).to receive(:pull_request).with('test-user/test-repo', 'test-pr-number').and_return(pr_data)
    allow(octokit_client).to receive_message_chain(:list_commits, :last, :sha).and_return('1234')
    allow(octokit_client).to receive(:pull_merged?).and_return(false)
    allow(octokit_client).to receive_message_chain(:pull_request_commits, :last, :sha).and_return('5678')
    allow(octokit_client).to receive(:check_suites_for_ref).and_return(head_commit_status)
  end

  context '#bubble_merge' do
    let(:commit_message) {
      <<~MESSAGE
        PR #test-pr-number merged

        Squiddy-bot has merged the branch test-branch
        into test-base-branch after rebase as requested by test-user
        in the PR #test-pr-number.

        Further details are listed below.

        Squiddy out.

      MESSAGE
    }

    it 'merges successfully' do
      expect(octokit_client).to receive(:merge).with(
        'test-user/test-repo',
        'test-base-branch',
        'test-branch',
        {
          commit_message: commit_message,
          merge_method: 'rebase',
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
        allow(octokit_client).to receive(:merge).and_raise(Octokit::Conflict.new)
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
        expect(octokit_client).not_to receive(:merge)
        subject.bubble_merge
      end

      it 'does not delete the branch' do
        expect(octokit_client).not_to receive(:delete_branch)
        subject.bubble_merge
      end
    end

    context 'when CI checks have not finished' do
      let(:head_commit_status) do
        {
          total_count: '2',
          check_suites: [
            {
              id: '1',
              status: 'completed',
              conclusion: 'success'
            },
            {
              id: '2',
              status: 'in_progress'
            }
          ]
        }
      end

      it 'does not merge the PR' do
        expect(octokit_client).not_to receive(:merge)
        subject.bubble_merge
      end
    end

    context 'when CI checks have failed' do
      let(:head_commit_status) do
        {
          total_count: '2',
          check_suites: [
            {
              id: '1',
              status: 'completed',
              conclusion: 'success'
            },
            {
              id: '2',
              status: 'completed',
              conclusion: 'failure'
            }
          ]
        }
      end

      it 'does not merge the PR' do
        expect(octokit_client).not_to receive(:merge)
        subject.bubble_merge
      end
    end
  end


end
