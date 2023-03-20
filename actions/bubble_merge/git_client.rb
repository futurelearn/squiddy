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
        wait_for_pr_to_match_branch do |merge_sha|
          merge_and_close_pr(merge_sha)
        end
      end
    end

    private

    def wait_for_pr_to_match_branch
      retry_sleeps = [1, 2, 3, 5, 8]

      loop do
        expected = branch_head_sha
        actual = pull_request_head_sha

        if actual == expected
          puts "PR HEAD #{actual[0..10]} matches #{branch} HEAD #{expected[0..10]}; merging..."
          yield expected
          return
        elsif s = retry_sleeps.shift
          puts "PR HEAD #{actual[0..10]} did not match #{branch} HEAD #{expected[0..10]}; waiting for #{s}s..."
          sleep s
          next
        else
          raise "PR HEAD #{actual[0..10]} did not match #{branch} HEAD #{expected[0..10]}; exiting"
        end
      end
    end

    def already_merged?
      client.pull_merged?(repo_name, pr_number)
    end

    def merge_and_close_pr(merge_sha)
      puts "PR ##{pr_number}: merging #{branch}@#{merge_sha} into #{base_branch}"
      client.merge_pull_request(
        repo_name,
        pr_number,
        commit_message,
        {
          merge_method: 'merge',
          sha: merge_sha
        }
      )
      delete_branch
    rescue StandardError => e
      message = <<~MESSAGE
        Oh no! Auto-merging could not be performed. Please fix all merge conflicts and try again.

        #### Error message:
        #{e&.message}
      MESSAGE
      client.add_comment(repo_name, pr_number, message)
    end

    def delete_branch
      return if repository.delete_branch_on_merge

      puts "PR ##{pr_number}: deleting #{branch}"
      client.delete_branch(repo_name, branch)
    end

    def branch
      pr.head.ref
    end

    def base_branch
      pr.base.ref
    end

    def pr_number
      event.dig('issue', 'number')
    end

    def branch_head_sha
      client.branch(repo_name, branch).commit.sha
    end

    def pull_request_head_sha
      client.pull_request(repo_name, pr_number).head.sha
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
      "Merge branch '#{branch}' into #{base_branch}"
    end

    def optional_message
      comment.nil? ? '' : "\n\nTriggering comment with optional details:\n\n#{comment}"
    end

    def commit_message
      <<~MESSAGE
        #{commit_title}

        Squiddy-bot has merged the branch #{branch}
        into #{base_branch} after rebase as requested by #{comment_author}
        in PR ##{pr_number}.

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

    def repository
      client.repository(repo_name)
    end
  end
end
