require 'trello'

module Squiddy
  class Trello
    class Checklist
      class CardNotFound < StandardError; end
      class ChecklistNotFound < StandardError; end

      attr_reader :card_url

      def initialize(card_url)
        @card_url = card_url
      end

      def create_checklist
        return checklist if checklist_exist?

        card.create_new_checklist('Pull Requests')
      end

      def checklist_exist?
        !checklist.nil?
      end

      def item_exist?(item)
        fail ChecklistNotFound unless checklist_exist?

        !item_id(item).nil?
      end

      def add_item(item)
        fail ChecklistNotFound unless checklist_exist?

        resp = checklist.add_item(item)

        resp.code == 200
      end

      def mark_item_as_complete(item)
        fail ChecklistNotFound unless checklist_exist?

        id = item_id(item)

        checklist.update_item_state(id, "complete")
        checklist.save

        true
      end

      def card_id_from_url
        fail StandardError, "Malformed URL" unless card_url =~ /#{URI::regexp(['http', 'https'])}/

        uri = URI.parse(card_url)
        path = uri.path

        # Trello cards look like https://trello.com/c/card-id
        fail CardNotFound unless uri.host =~ /^trello\.com$/
        fail CardNotFound unless path =~ /^\/c\/.*$/

        path.split("/").reject { |p| p.empty? }[1]
      end

      private

      def card
        begin
          ::Trello::Card.find(card_id_from_url)
        rescue
          fail CardNotFound
        end
      end

      def checklist
        card.checklists.find { |checklist| checklist.name == "Pull Requests" }
      end

      def item_id(name)
        i = card.checklists.first.items.find { |item| item.name == name }

        return nil if i.nil?

        i.id
      end
    end
  end
end
