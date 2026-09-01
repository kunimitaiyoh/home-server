---
name: merge
description: Merge one or more commits into the current branch with `git merge --no-edit`, resolve mechanical conflicts, repair semantic regressions, and report every non-obvious judgment after the merge completes. Invocation form `/merge <commit>...`.
disable-model-invocation: true
---

# Merge

Merge the given commits into the current branch, resolve conflicts, repair
semantic regressions introduced by the combination of the sides, and complete
the merge commit. Every judgment that could not be settled by obvious logic is
made autonomously with best judgment — and reported, without exception, after
the merge finishes.

## Arguments

One or more `<commit>` arguments (commits, usually branch heads, to merge into
the current branch). If none was supplied, ask the user for them and stop —
never pick a commit yourself.

## Preconditions

Check all of these before touching the repository. If any fails, report which
one and stop without doing anything:

1. Every argument resolves via `git rev-parse --verify <commit>^{commit}`.
2. `git status --porcelain` is empty (clean working tree and index).
3. `git symbolic-ref -q HEAD` succeeds (not a detached HEAD).

## Behavior of multi-head `git merge` (verified)

Passing more than one commit produces an octopus merge. Points that differ
from a two-head merge:

- On conflict it stops in a conflicted (`UU`) state rather than aborting; all
  heads are recorded in `.git/MERGE_HEAD`, and `git commit --no-edit` after
  resolution produces an N-parent merge commit.
- Conflict-marker labels are temporary file names (`<<<<<<< .merge_file_*`),
  not branch names — never identify a side by its marker label.
- If the base is an ancestor of one head, git fast-forwards to it first, so
  the number of parents may not match the number of arguments.
- The octopus strategy is not `ort`: `-X` strategy options and ort's rename
  detection do not apply.

## Process

1. Record `git rev-parse HEAD` before merging.
2. Run a single `git merge --no-edit <commit>...` with all arguments — do not
   split it into sequential merges.
3. If there are conflicts, list them with
   `git diff --name-only --diff-filter=U` and resolve file by file. Identify
   which side a change belongs to with `git ls-files -u <path>` (stage 1 =
   base, 2 = ours, 3 = theirs) and `git log --merge -p -- <path>`, never from
   the conflict markers. Preserve the intent of every side; do not discard one
   side's change just to make a conflict disappear.
4. `git add` each resolved file. Do not commit yet.
5. Inspect for semantic regressions (below), fix them, and `git add` the
   fixes.
6. Run the project's verification commands (below). For each failure, judge
   whether it originates from the merge; if it does, fix it and rerun.
7. Create the merge commit with `git commit --no-edit`.
8. Output the report (below).

## Obvious versus non-obvious resolutions

Obvious — resolve, and report only the count and file names:

- Both sides added mutually independent lines in the same hunk, and keeping
  both suffices.
- One side is formatting or reordering only, with no semantic change.
- Additions to a list whose order carries no meaning (imports, dependency
  lists).
- After normalization one side is a strict superset of the other, or both are
  identical.

Non-obvious — resolve with best judgment, and report every instance:

- Both sides changed the same logic or the same value differently.
- One side changed something another side deleted or renamed.
- The resolution requires choosing an intent, a value, or an order, and the
  choice changes behavior.
- The correctness of the judgment cannot be backed by execution.

## Semantic regressions

A semantic regression is breakage produced by the combination of the sides
even though the merge itself completed without conflict. Establish what each
side changed from `git merge-base` using `git log --name-status` and
`git diff`. Fix only regressions created by the combination; a problem that
already existed on a single side is reported, never fixed.

### Broken references

The merged tree no longer works because the sides changed mutually dependent
locations separately. Look for: a signature changed on one side and new call
sites added on another; an export deleted or renamed on one side and newly
imported on another; a data structure changed on one side and newly consumed
on another; renamed constants or configuration keys; changed default
arguments. For every identifier a side deleted or renamed, grep the whole
merged tree for stale references.

### Invariants established by one side

A merge can also break a property that no single line is responsible for:
one side made some property hold uniformly across many locations, and
another side's changes, written before or without that sweep, reintroduce
exceptions to it. The merged tree must keep the property over the range the
sweep reached, including the locations the other sides brought in.

Examples of such sweeps — illustrative, not exhaustive; judge by the shape
of the side's diff, not by resemblance to this list:

- one side converts every string literal to the other quote style, while
  another side adds code still using the old style;
- one side renames a recurring identifier or vocabulary term everywhere,
  while another side adds new occurrences of the old name;
- one side migrates every call site from a deprecated API to its
  replacement, while another side adds a new call to the deprecated one;
- one side reorders or regroups a construct (imports, object keys, case
  arms) to a single scheme, while another side inserts entries following
  the old scheme.

Bring the other sides' added or changed locations under the swept rule —
never the reverse; do not undo the sweep to match the code that arrived
beside it. Confine this to the range the sweep actually reached, and leave
locations no side changed alone. Do not derive a rule from your own
preference — only from what a side's diff exhibits. Where the rule or its
range is unclear, or the fix would be too broad to verify, change nothing
and report it.

Judgments in this class are always non-obvious: report every one, never fold
them into the count-only section.

## Verification commands

Detect the project's own verification commands (`package.json` scripts,
`Makefile`, `justfile`, CI workflows) and run whatever corresponds to
typecheck, lint, and test. If none can be detected, state so in the report.
If a failure is judged to predate the merge (it already existed on a single
side), do not fix it; report the judgment and its grounds.

## Report

Write the report in the language of the conversation, always, after the merge
completes — even when everything resolved obviously.

1. Summary: the merged commits, the resulting merge commit, its parent count,
   the number of conflicted files, the number of non-obvious judgments, and
   the verification results.
2. Non-obvious conflict resolutions: a sequential number, `file:line`, what
   each side had, the resolution taken, its grounds, and any remaining risk.
3. Semantic regressions: what was detected, what was fixed, and the grounds;
   anything left unfixed, with the reason.
4. Verification command results, including any unresolved failure and the
   judgment about it.
5. Obviously resolved conflicts: count and file names only.

## Never

- `git rebase`, `git commit --amend`, `git push`, or any history rewriting.
- `git merge --abort` — apart from stopping at the precondition checks, the
  merge is carried to completion.
- Strategy options that mechanically take one side (`-X ours`, `-X theirs`,
  `--strategy=ours`).
