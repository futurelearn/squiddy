require 'spec_helper'

require_relative '../../../lib/squiddy/pull_request'

RSpec.describe Squiddy::PullRequest do
  subject { described_class.new('test/repository', 1) }

  let(:client) { double(Octokit::Client) }

  before do
    allow(Octokit::Client).to receive(:new).and_return(client)

    allow(client).to receive(:pull_request).and_return({
      body: "I contain a matched-string",
      html_url: "https://github.com/test/repository/pull/1",
      state: "closed",
      labels: [{name: 'test-label'}],
      title: "Pull request name"
    })
  end

  describe '#body_matches_regex?' do
    it 'returns true when there is a match' do
      expect(subject.body_matches_regex?(/matched-string/)).to eq(true)
    end

    it 'returns false when there is no match' do
      expect(subject.body_matches_regex?(/non-matched-string/)).to eq(false)
    end
  end

  describe '#body_regex' do
    it 'returns the matched string if there is a match' do
      expect(subject.body_regex(/matched-string/)).to eq("matched-string")
    end

    it 'returns nil if there is no match' do
      expect(subject.body_regex(/foo/)).to eq(nil)
    end
  end

  describe '#url' do
    it 'returns the pull request URL' do
      expect(subject.url).to eq("https://github.com/test/repository/pull/1")
    end
  end

  describe '#open?' do
    it 'returns false when the pull request is closed' do
      expect(subject.open?).to eq(false)
    end
  end

  describe '#closed?' do
    it 'returns true when the pull request is closed' do
      expect(subject.closed?).to eq(true)
    end
  end

  describe '#labels' do
    it 'returns the label names as an array' do
      expect(subject.labels).to eq(['test-label'])
    end
  end

  describe '#body' do
    it 'returns the body of the pull request' do
      expect(subject.body).to eq("I contain a matched-string")
    end
  end

  describe '#title' do
    it 'returns the title of the pull request' do
      expect(subject.title).to eq("Pull request name")
    end
  end
end
