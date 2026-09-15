---
name: special-review
description: Review the diff against the base branch using the user's personal code-quality criteria, extracted from their past review feedback. Report only — never modifies code. Use when the user asks for a special review of a branch or diff.
---

# Special Review

Review the diff between the base branch and HEAD against the user's personal code-quality criteria. This skill produces a report only.

## Scope

- Report only. Do NOT modify any file (no Edit/Write). Proposed fix snippets inside the report are fine; applying them requires the user's explicit per-item instruction afterward.
- Do not assert what you cannot substantiate. Any finding you cannot back with concrete evidence must be reported as a question, not a violation.

## Arguments

All optional, parsed from the free-form argument text:

- `base=<ref>` — explicit base branch/revision.
- `group=<status|category|file>` — report grouping. Default: `status`.
- Any remaining text — the task instruction used for scope judgment.

Base resolution order:

1. The `base=` argument.
2. The repository default branch via `git symbolic-ref refs/remotes/origin/HEAD`.
3. If neither resolves, do not guess — ask the user and stop.

## Process

1. Resolve the base (above).
2. Get the diff: `git diff <base>...HEAD` and `git log <base>..HEAD --oneline`. If the diff is empty, report that and stop.
3. For each changed file, read the adjacent existing code: similar files in the same directory, the patterns the change should follow, and project-level conventions. This step is mandatory — the convention, interface-leakage, and naming criteria cannot be judged from the diff alone.
4. Determine the task context for scope judgment: the argument text if given; otherwise the work instructions in the current conversation, but only when the diff corresponds to work done in this session — never infer from unrelated conversation. If neither exists, run in candidates-only mode.
5. Apply the criteria below to all changed files, collecting each finding with file:line and its grounds.
6. Output the report and stop.

## Criteria

Common principle: each criterion has a default status below, but any finding you cannot substantiate with concrete grounds must be demoted to a question. Refer to criteria by name, not by number, to avoid confusion with finding numbers.

### Violations (assertable)

- **Type-level invariants**: casual `?.` / `??`, optional properties or parameters for essentially required values, fallbacks for required values (e.g. casual `??` / `||` fallbacks, empty-string defaults), and unreachable defensive code (e.g. unnecessary `typeof window` guards) — unless the surrounding code makes the legitimacy evident.
- **Cargo-cult abstraction**: provider wrappers, barrel exports, file splits, hasty commonization, or extra layers with no demonstrated effectiveness.
- **Formatting negligence**: broken indentation and other mechanically verifiable formatting problems.
- **Interface leakage**: DB structure, internal abbreviations, or infrastructure vocabulary leaking into API names or into vocabulary across a boundary; carrying an existing bad name across a boundary it should not cross.
- **Indirect or misleading naming**: names clearly detached from what the thing actually is or does. Include a more direct (dumb) alternative. If judgment could reasonably differ, demote to a question.

### Questions (ask for grounds; do not assert)

- **Ungrounded values and constraints**: enumerate values, constraints, wording, and default values whose basis is not visible, and ask for their grounds.
- **Convention mismatch**: where the diff deviates from adjacent conventions, ask the reason for the deviation, and attach your own assessment — with grounds — of whether the existing convention itself is bad. Do not pass final judgment: conventions should be followed unless they are bad, and deviation needs a legitimate reason, but whether such a reason existed is not knowable from the diff.

### Candidates (require matching against the task instruction)

- **Out-of-scope changes**: comments, tests, config changes, options, or incidental refactoring not called for by the instruction. With task context available, judge and promote confirmed items to violations; without it, list them as candidates needing confirmation.
- **Suspected symptom patching**: special-case branches, a guard added at only one call site, and similar signs that a symptom was plugged rather than the root cause fixed. Report as suspicion.
- **Attribution in documents** (only when documents are part of the diff): statements recorded as the user's decisions must have a traceable source; flag places where AI analysis and the user's stated intent are indistinguishable.

## Report format

Write the report in the language of the conversation.

- Number every finding `#1, #2, …` — unique across the whole report regardless of grouping, so the user can reference findings in the following conversation.
- Start with a short summary: base, commit count, changed-file count, and whether task context was available.
- `group=status` (default): three sections — violations, questions, candidates. State "none" explicitly for empty sections.
- `group=category`: sections per criterion, each finding annotated with its status.
- `group=file`: sections per changed file, each finding annotated with its status.
- Every finding must include: its number, file:line, the content, and the grounds (what adjacent code, convention, or principle it was judged against).
- No severity labels.
