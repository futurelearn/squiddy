require 'spec_helper'

require_relative '../../../lib/squiddy/git_client'

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
  let(:oktokit_client) { instance_double('Octokit::Client', :oktokit_client) }
  let(:pr_data) {
    {
      base: { ref: 'test-base-branch' },
      head: { ref: 'test-branch' }
    }
  }

  before do
    allow(ENV).to receive(:[]).with('GITHUB_EVENT').and_return(event)
    allow(ENV).to receive(:[]).with('GITHUB_TOKEN').and_return('token')
    allow(ENV).to receive(:key?).with('GITHUB_EVENT').and_return(true)
    allow(ENV).to receive(:key?).with('GITHUB_TOKEN').and_return(true)
    allow(Octokit::Client).to receive(:new).with({ access_token: 'token' }).and_return(oktokit_client)
    allow(oktokit_client).to receive(:pull_request).with('test-repo', 'test-pr-number').and_return(pr_data)
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
