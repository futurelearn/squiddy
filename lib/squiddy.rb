require_relative 'squiddy/event'
require_relative 'squiddy/pull_request'
require_relative 'squiddy/trello_checklist'

module Squiddy
  # TrelloPullRequest automatically creates a checklist on a Trello card called
  # "Pull Requests", and adds the pull request URL as an item.
  #
  # If the Pull Request is in a closed state, then it marks the item as
  # complete
  class TrelloPullRequest
    def self.run(pull_request_number:)
      fail "pull_request_number is nil" if pull_request_number.nil?

      event = Squiddy::Event.new

      return nil unless event.type == "pull_request"
      pull_request = Squiddy::PullRequest.new(event.repository, pull_request_number)

      trello_regex = /https:\/\/trello\.com\/c\/\w+/

      trello_card = pull_request.body_regex(trello_regex)
      return nil unless trello_card

      begin
        trello = Squiddy::TrelloChecklist.new(trello_card)

        item = pull_request.url

        if pull_request.open?
          trello.create_checklist unless trello.checklist_exist?

          trello.add_item(item) unless trello.item_exist?(item)
        end

        if pull_request.closed?
          trello.mark_item_as_complete(item) if trello.item_exist?(item)
        end
      rescue Squiddy::TrelloChecklist::ChecklistNotFound => e
        e.message
      end
    end
  end
end
