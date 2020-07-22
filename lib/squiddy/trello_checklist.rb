module Squiddy
  class TrelloChecklist
    attr_reader :card_url

    def initialize(card_url)
      @card_url = card_url
    end

    def create_checklist
    end

    def checklist_exist?
    end

    def add_item(item)
    end

    def mark_item_as_complete(item)
    end
  end
end
