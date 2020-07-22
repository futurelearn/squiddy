require 'spec_helper'

require_relative '../../../lib/squiddy/git_client'

RSpec.describe Squiddy::GitClient do
  subject { described_class.new }

  describe '#branch' do
    it 'returns information about the user' do
      expect { subject }.not_to raise_error
    end
  end
end
