require 'spec_helper'

require_relative '../../../lib/squiddy/event'

RSpec.describe Squiddy::Event do
  subject { described_class.new }

  before do
    @original_repository = ENV['GITHUB_REPOSITORY']

    ENV['GITHUB_REPOSITORY'] = "futurelearn/test"
  end

  after do
    ENV['GITHUB_REPOSITORY'] = @original_repository
  end

  describe '#organisation' do
    it 'should return the organisation name' do
      expect(subject.organisation).to eq('futurelearn')
    end
  end

  describe '#short_repository' do
    it 'should return the name of the repository minus the organisation' do
      expect(subject.short_repository).to eq('test')
    end
  end

  context 'when the event is a pull request' do
    before(:each) do
      @original_event_name = ENV['GITHUB_EVENT_NAME']
      @original_ref = ENV['GITHUB_REF']

      ENV['GITHUB_EVENT_NAME'] = "pull_request"
      ENV['GITHUB_REF'] = "refs/pull/8/merge"
    end

    after(:each) do
      ENV['GITHUB_EVENT_NAME'] = @original_event_name
      ENV['GITHUB_REF'] = @original_ref
    end

    describe '#pull_request_number' do
      it 'should output the pull request number' do
        expect(subject.pull_request_number).to eq(8)
      end
    end
  end
end
