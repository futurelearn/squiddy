FROM ruby:slim

COPY entrypoint.rb /opt/entrypoint.rb

ENTRYPOINT ["ruby", "/opt/entrypoint.rb"]
