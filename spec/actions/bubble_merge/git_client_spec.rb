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
        'full_name': 'test-repo'
      }
    }.to_json
  }
  let(:pr_data) {
    {
      base: { ref: 'test-base-branch' },
      head: { ref: 'test-branch' }
    }
  }
  let(:octokit_client) { instance_double('Octokit::Client') }

  before do
    stub_const('ENV', 'GITHUB_EVENT' => event, 'GITHUB_TOKEN' => 'token')
    allow(Octokit::Client).to receive(:new).and_return(octokit_client)
    allow(octokit_client).to receive(:pull_request).with('test-repo', 'test-pr-number').and_return(pr_data)
  end

  it 'returns the branch name' do
    expect(subject.branch).to eq('test-branch')
  end

  it 'returns the base branch name' do
    expect(subject.base_branch).to eq('test-base-branch')
  end

  it 'returns repo name' do
    expect(subject.repo).to eq('test-repo')
  end

  it 'returns pr number' do
    expect(subject.pr_number).to eq('test-pr-number')
  end

  it 'returns the pr' do
    expect(subject.pr).to eq(pr_data)
  end
end
