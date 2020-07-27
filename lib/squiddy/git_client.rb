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
        comment_start
        begin
          rebase_branch_off_master
          merge_branch_into_master
          delete_branch
          comment_finish
        rescue Octokit::Conflict => e
          client.add_comment(repo, pr_number, 'There was a merge conflict. Auto-merging could not be performed. Please fix all conflicts and try again.')
        end
      end
    end

    def rebase_branch_off_master
      client.merge(repo, branch, base_branch, { merge_method: 'rebase' })
    end

    def merge_branch_into_master
      client.merge_pull_request(repo, pr_number, '', { merge_method: 'rebase', commit_title: commit_title, commit_message: commit_message })
    end

    def master_sha
      client.list_commits(repo).last.sha
    end

    def delete_branch
      client.delete_branch(repo, branch)
    end

    def comment_start
      client.add_comment(repo, pr_number, 'Roger that!')
    end

    def comment_finish
      client.add_comment(repo, pr_number, 'Merged into master')
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

    def comment
      event.dig('comment', 'user', 'body')
    end

    private

    def commit_title
      "PR #{pr_number} merged"
    end

    def commit_message
      <<~MESSAGE
        Squiddy has merged the branch
        `#{branch}`
        as requested by
        `#{comment_author}`
        with a comment in the PR[1].

        Further details are listed below[2].

        Squiddy out.

        [1]
        #{pr_number}

        [2]
        #{comment}
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
