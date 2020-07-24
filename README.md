# Squiddy

![](squiddy.gif)

Squiddy is a collection of GitHub Actions tools.

There are separate actions to use in the [`actions`](actions) directory.

There is a main squiddy action that can be run as a pre-built Docker image or as a Ruby gem.

## Squiddy Collection action

Currently only performs a single task.

### Pull Request Trello Checklist

If a link to a Trello card is found in the Pull Request description, a
checklist will be created in the Trello card with a link to the Pull Request.

## Pre-built Docker image

The Docker image is built on Alpine, and can take up to 30s to run.

```
on:
  pull_request:
    types: [ opened, closed, edited, reopened ]

jobs:
  test:
    runs-on: ubuntu-latest
    env:
      SQUIDDY_GITHUB_ACCESS_TOKEN: ${{ secret.GITHUB_TOKEN }}
      SQUIDDY_TRELLO_DEVELOPER_PUBLIC_KEY: ${{ secret.TRELLO_DEVELOPER_PUBLIC_KEY }}
      SQUIDDY_TRELLO_MEMBER_TOKEN: ${{ secret.TRELLO_MEMBER_TOKEN }}
    steps:
    - uses: docker://futurelearn/squiddy
```

## Ruby gem

This is the quickest way to run the action, since once the gem is cached it's
very quick to start, and can run in under 10s.

Requires access to our private GitHub Rubygems repository.

```
on:
  pull_request:
    types: [ opened, closed, edited, reopened ]

jobs:
  test:
    runs-on: ubuntu-latest
    env:
      SQUIDDY_GITHUB_ACCESS_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      SQUIDDY_TRELLO_DEVELOPER_PUBLIC_KEY: ${{ secrets.TRELLO_DEVELOPER_PUBLIC_KEY }}
      SQUIDDY_TRELLO_MEMBER_TOKEN: ${{ secrets.TRELLO_MEMBER_TOKEN }}
    steps:
    - name: Setup Squiddy Gem
      run: |
       cat << EOF > Gemfile
       source "https://rubygems.org"
       source "https://rubygems.pkg.github.com/futurelearn" do
         gem "squiddy"
       end
       EOF
       mkdir -p ~/.bundle
       echo "BUNDLE_HTTPS://RUBYGEMS__PKG__GITHUB__COM/FUTURELEARN/: squiddy-bot:${{ secrets.GITHUB_TOKEN }}" > ~/.bundle/config
    - uses: ruby/setup-ruby@v1
      with:
        ruby-version: 2.7.1
        bundler-cache: true
    - run: bundle exec squiddy
```
