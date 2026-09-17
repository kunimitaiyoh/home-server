---
name: address-review
description: Address the valid review comments on the current branch's pull request. Judges each unresolved review thread, applies changes for the valid ones, and reports every judgment. Leaves changes uncommitted and writes nothing to GitHub. Invocation form `/address-review`.
disable-model-invocation: true
---

# Address Review

Go through the unresolved review threads on the current branch's pull request,
decide for each whether the comment is valid, make the change for every valid
one, and report every judgment. Do not commit, and do not write anything to
GitHub.

## Preconditions

Stop without doing anything if any of these fails, in this order:

1. The working tree and index are clean: `git status --porcelain` reports
   nothing, except untracked entries that are linked worktrees of this
   repository (listed by `git worktree list`), which do not count.
2. `git pull --ff-only` succeeds.
3. `git rev-parse HEAD` equals `headRefOid` from `gh pr view --json headRefOid`.
   A local branch that is ahead of the pull request cannot be brought into
   agreement with it without pushing, so the skill does not proceed.

## Fetching the threads

Resolve the pull request with `gh pr view --json number`, and the repository
with `gh repo view --json owner,name` (the owner is `.owner.login`). Resolved
state is not available through `gh pr view`; use GraphQL:

```
gh api graphql -f query='query($owner:String!,$repo:String!,$pr:Int!,$after:String){repository(owner:$owner,name:$repo){pullRequest(number:$pr){reviewThreads(first:100,after:$after){pageInfo{hasNextPage endCursor}nodes{id isResolved isOutdated path line startLine comments(first:50){nodes{author{login} body createdAt diffHunk url}}}}}}}' -F owner=<owner> -F repo=<repo> -F pr=<number>
```

While `pageInfo.hasNextPage` is true, repeat with `-F after=<endCursor>`. Keep
only threads with `isResolved == false`.

## Judging

A comment is valid when its premise holds true of the code as it currently is,
the problem was introduced by this pull request's own changes, and the change
it asks for can be identified. Judge with your own reading of the code, not by
taking the comment's word for it. When the judgment is uncertain, decide with
best judgment and state the uncertainty in the report.

## Report

In the language of the conversation, report every thread: the judgment, its
grounds, and — for a comment addressed — what was changed. Note that the
changes are uncommitted and that nothing was written to GitHub.
