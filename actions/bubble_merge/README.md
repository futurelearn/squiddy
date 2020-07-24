## Bubble merge

## When does it trigger?

Merges your PR into master when you comment `@squiddy-bot merge` on your PR.

## What does it do?

1. Rebase your branch off master.
2. Merge your branch into master without a merge commit. This will close the PR.
3. Delete your branch.

NB: If the PR has conflicts with the base branch, these will need to be handled
manually (e.g. if you've changed a file that has also been changed on master 
after you opened your PR).

## How do I use this action in my repo?

Create a file in `.github/workflows/bubble_mergey.ml` with the following:

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
      - uses: futurelearn/squiddy/actions/bubble_merge@mt-et-bubble-merge
        env:
          GITHUB_TOKEN: ${{ secrets.SQUIDDY_BOT_GITHUB_TOKEN }}
          GITHUB_EVENT: ${{ toJson(github.event) }}
``` 
