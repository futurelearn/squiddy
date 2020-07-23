require 'octokit'

module Squiddy
  class PullRequest
    attr_reader :client, :object

    def initialize(repository, number, access_token: nil)
      @client = Octokit::Client.new(access_token: access_token || ENV['SQUIDDY_GITHUB_ACCESS_TOKEN'])

      @object ||= client.pull_request(repository, number)
    end

    def body_matches_regex?(regex)
      if object[:body] =~ regex
        true
      else
        false
      end
    end

    def url
      object[:html_url]
    end
  end
end
