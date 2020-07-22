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

    def branch
      event.dig("pull_request", "head", "ref")
    end

    def raw_event
      File.read(ENV["GITHUB_EVENT_PATH"])
    end

    def event
      unless ENV.key?("GITHUB_EVENT_PATH")
        raise "No GITHUB_EVENT_PATH env var found. This script is designed to run via github actions, which will provide the github event via this env var."
      end

      JSON.parse File.read(ENV["GITHUB_EVENT_PATH"])
    end
  end
end
