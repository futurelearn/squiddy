## Bubble merge

## When does it trigger?

Merges your PR into master when you comment `@squiddy-bot merge` on your PR.

## What does it do?

1. Rebases your branch off master (see note A below)
2. Merges your branch into master with no fastforward 
3. The merge commit includes your comment (see note B below)
4. (This closes the PR too)
5. Deletes your branch

Notes:

A. If the PR has conflicts with the base branch, Squiddy will stop the action
and warn you that these conflicts will need to be handled manually  (e.g. if
you've changed a file that has also been changed on master  after you opened
your PR).

B. The merge commit title indicates the number of the PR. The commit message
includes the name of the branch and the username of the person triggering the
action. It also includes the entire text of the comment containing the
triggering command, at the bottom of the commit message.

## How do I use this action in my repo?

Create a file in `.github/workflows/bubble_merge.yml` with the following:

```yaml
name: Bubble Merge
on:
  issue_comment:
    types: [created]
    branches-ignore:
      - master

jobs:
  bubble_merge:
    name: Bubble Merge
    if: github.event.issue.pull_request != '' && contains(github.event.comment.body, '@squiddy-bot merge')
    runs-on: ubuntu-latest
    steps:
      - name: Checkout the latest code
        uses: actions/checkout@main
        with:
          fetch-depth: 0
      - name: Automatic Rebase
        uses: cirrus-actions/rebase@1.3.1
        env:
          GITHUB_TOKEN: ${{ secrets.SQUIDDY_BOT_GITHUB_TOKEN }}
      - name: Acknowledge Failure
        if: ${{ failure() }}
        uses: actions/github-script@0.9.0
        with:
          github-token: ${{secrets.SQUIDDY_BOT_GITHUB_TOKEN}}
          script: |
            await github.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: 'Rebase was not possible. Please rebase manually and try again.'
            })
      - uses: futurelearn/squiddy/actions/bubble_merge@master
        env:
          GITHUB_TOKEN: ${{ secrets.SQUIDDY_BOT_GITHUB_TOKEN }}
          GITHUB_EVENT: ${{ toJson(github.event) }}
``` 
