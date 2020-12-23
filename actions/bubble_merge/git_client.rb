require "octokit"
require "json"

module Squiddy
  class GitClient
    attr_reader :client, :event, :pr, :repo

    def initialize
      unless ENV.key?("GITHUB_TOKEN")
        raise "No GITHUB_TOKEN env var found"
      end

      @client = Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])
      @event = git_event
      @repo = repo_name
      @pr = pull_request
    end

    def bubble_merge
      unless client.pull_merged?(repo, pr_number)
        begin
          merge_bubble_branch_into_master
          delete_branch
        rescue StandardError => e
          message = <<~MESSAGE
            Oh no! Auto-merging could not be performed. Please fix all merge conflicts and try again.

            #### Error message:
            #{e&.message}
          MESSAGE
          client.add_comment(repo, pr_number, message)
        end
      end
    end

    private

    def merge_bubble_branch_into_master
      client.merge(
        repo,
        base_branch,
        branch,
        {
          merge_method: 'rebase',
          commit_message: commit_message,
          sha: master_sha
        }
      )
    end

    def master_sha
      client.list_commits(repo).last.sha
    end

    def delete_branch
      client.delete_branch(repo, branch)
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
      client.pull_request(repo, pr_number)
    end
  end
end
