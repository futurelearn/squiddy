require "octokit"
require "json"

module Squiddy
  class GitClient
    attr_reader :client

    def initialize
      unless ENV.key?("GITHUB_TOKEN")
        raise "No GITHUB_TOKEN env var found. Please make this available via the github actions workflow\nhttps://help.github.com/en/articles/virtual-environments-for-github-actions#github_token-secret"
      end

      @client = Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])
    end
  end
end
