# Squiddy

![](squiddy.gif)

Squiddy is a collection of GitHub Actions tools.

There are separate actions to use in the [`actions`](actions) directory.

There is a main squiddy action that can be run as a pre-built Docker image.

## Squiddy Collection action

Currently only performs a single task.

### Pull Request Trello Checklist

If a link to a Trello card is found in the Pull Request description, a
checklist will be created in the Trello card with a link to the Pull Request.

## Example

```
name: Squiddy Bot
on:
  pull_request:
    types: [ opened, closed, edited, reopened ]

jobs:
  squiddy:
    runs-on: ubuntu-latest
    env:
      SQUIDDY_GITHUB_ACCESS_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      SQUIDDY_ISSUE_NUMBER: ${{ github.event.number }}
      SQUIDDY_TRELLO_DEVELOPER_PUBLIC_KEY: ${{ secrets.TRELLO_DEVELOPER_PUBLIC_KEY }}
      SQUIDDY_TRELLO_MEMBER_TOKEN: ${{ secrets.TRELLO_MEMBER_TOKEN }}
    steps:
    - uses: docker://futurelearn/squiddy
```
