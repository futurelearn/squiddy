require 'trello'

Trello.configure do |config|
  config.developer_public_key = ENV['SQUIDDY_TRELLO_DEVELOPER_PUBLIC_KEY'],
  config.member_token = ENV['SQUIDDY_TRELLO_MEMBER_TOKEN']
end
