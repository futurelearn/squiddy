FROM ruby:2.7.1-alpine

RUN mkdir -p /app
WORKDIR /app

RUN apk add build-base

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development --system

COPY . .

ENTRYPOINT ["/app/bin/squiddy"]
