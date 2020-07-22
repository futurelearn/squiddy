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

    def card_id_from_url(url)
      fail StandardError, "Malformed URL" unless url =~ /#{URI::regexp(['http', 'https'])}/

      uri = URI.parse(url)
      path = uri.path

      # Trello cards look like https://trello.com/c/card-id
      fail CardNotFound unless uri.host =~ /^trello\.com$/
      fail CardNotFound unless path =~ /^\/c\/.*$/

      path.split("/").reject { |p| p.empty? }[1]
    end
  end
end
