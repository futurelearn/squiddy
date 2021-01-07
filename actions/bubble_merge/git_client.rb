require "octokit"
require "json"

module Squiddy
  class GitClient
    attr_reader :client, :event, :pr

    CHECK_STATUSES = %w[queued in_progress completed].freeze
    CHECK_CONCLUSIONS = %w[success failure neutral cancelled skipped timed_out action_required stale].freeze

    def initialize
      unless ENV.key?("GITHUB_TOKEN")
        raise "No GITHUB_TOKEN env var found"
      end

      @client = Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])
      @event = git_event
      @pr = pull_request
    end

    def bubble_merge
      if already_merged?
        client.add_comment(repo_name, pr_number, 'This PR is already merged.')
      else
        merge_and_close_pr
      end
    end

    private

    def already_merged?
      client.pull_merged?(repo_name, pr_number)
    end

    def merge_and_close_pr
      merge
      delete_branch
    rescue StandardError => e
      message = <<~MESSAGE
        Oh no! Auto-merging could not be performed. Please fix all merge conflicts and try again.

        #### Error message:
        #{e&.message}
      MESSAGE
      client.add_comment(repo_name, pr_number, message)
    end

    def merge
      client.merge(
        repo_name,
        base_branch,
        branch,
        {
          merge_method: 'rebase',
          commit_message: commit_message,
          sha: main_sha
        }
      )
    end

    def delete_branch
      client.delete_branch(repo_name, branch)
    end

    def main_sha
      client.list_commits(repo_name).last.sha
    end

    def branch
      pr[:head][:ref]
    end

    def base_branch
      pr[:base][:ref]
    end

    def pr_number
      event.dig('issue', 'number')
    end

    def pr_status
      checks = head_commit_checks[:check_suites]

      if checks.any? { |check| check[:status] != 'completed' }
        'pending'
      elsif checks.any? { |check| check[:conclusion] != 'success' }
        'failure'
      else
        'success'
      end
    end

    def head_commit_checks
      client.check_suites_for_ref(repo_name, head_commit_sha)
    end

    def head_commit_sha
      client.pull_request_commits(repo_name, pr_number).last.sha
    end

    def comment_author
      event.dig('comment', 'user', 'login')
    end

    def comment_author_link
      event.dig('comment', 'user', 'html_url')
    end

    def comment
      event.dig('comment', 'body')
    end

    def commit_title
      "PR ##{pr_number} merged"
    end

    def optional_message
      comment.nil? ? '' : "\n\nTriggering comment with optional details:\n\n#{comment}"
    end

    def commit_message
      <<~MESSAGE
        #{commit_title}

        Squiddy-bot has merged the branch #{branch}
        into #{base_branch} after rebase as requested by #{comment_author}
        in the PR ##{pr_number}.

        Further details are listed below.

        Squiddy out.
        #{optional_message}
      MESSAGE
    end

    def git_event
      unless ENV.key?("GITHUB_EVENT")
        raise "No GITHUB_EVENT env var found"
      end

      JSON.parse ENV["GITHUB_EVENT"]
    end

    def repo_name
      event.dig('repository', 'full_name')
    end

    def pull_request
      client.pull_request(repo_name, pr_number)
    end
  end
end
