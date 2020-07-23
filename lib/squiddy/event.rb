module Squiddy
  class Event
    attr_reader :type

    def initialize
      @type = event_name
    end

    def organisation
      repository.split("/").first
    end

    def short_repository
      repository.split("/").last
    end

    def pull_request_number
      return nil unless type == "pull_request"

      # refs/pull/8/merge
      ref.split("/")[2].to_i
    end

    # These are the default environment variables set by GitHub Actions. They
    # change based upon the event type. See the documentation for what they
    # provide:
    # https://docs.github.com/en/actions/configuring-and-managing-workflows/using-environment-variables
    def convert(name)
      ENV["GITHUB_#{name.upcase}"]
    end

    def action
      convert "action"
    end

    def actions
      convert "actions"
    end

    def actor
      convert "actor"
    end

    def api_url
      convert "api_url"
    end

    def base_ref
      convert "base_ref"
    end

    def event_name
      convert "event_name"
    end

    def event_path
      convert "event_path"
    end

    def graphql_url
      convert "graphql_url"
    end

    def head_ref
      convert "head_ref"
    end

    def ref
      convert "ref"
    end

    def repository
      convert "repository"
    end

    def run_id
      convert "run_id"
    end

    def run_number
      convert "run_number"
    end

    def server_url
      convert "server_url"
    end

    def sha
      convert "sha"
    end

    def workflow
      convert "workflow"
    end
  end
end
