# Design principles

- Do not preserve backward compatibility. Remove obsolete paths instead of adding compatibility layers, fallbacks, or migrations.
- Choose the simplest implementation that fully meets the current requirements. Avoid speculative abstractions, configuration, and indirection. Don't justify a heavy structure (a new store, extra contexts, additional layers) on weak grounds; first ask whether a simpler means works, and verify the necessity before asserting it.
- Grow the system in layers. Start from the smallest version that works end to end, and add each new capability on top of a product that already works. Never trade a working product for unfinished complexity.
- Keep components modular and concerns clearly separated.
- Prefer established, well-maintained libraries when they reduce overall complexity or improve reliability. Do not reimplement common functionality without a clear reason.
- Lean on the dependencies already in the project before writing your own implementation or adding packages. Do not assume a library lacks a capability without checking its documentation and types.
- Make architectural decisions for the long term. Do not accept a stopgap that only works for now and is meant to be replaced later.
- Study how established products solve the problem before designing a solution. Adopt their proven patterns and conventions rather than inventing an approach from scratch.

# Ground everything; verify before claiming

- Base every line of code and every claim on evidence. Never assert from guesswork.
- Don't answer feasibility questions ("Can you…?", "Is it possible…?") off the cuff. Check official documentation, type definitions, and actual behavior first, then answer conditionally ("possible if X; not possible for Y"). Consult official documentation before firing off exploratory commands.
- When the spec is unclear, don't assume one and write code anyway (e.g., don't silently fill in "filter by the given condition"). Specs are for humans to decide.
- Make code correspond strictly to what actually exists. Never fabricate APIs, helpers, or queries, and never guess a function's default argument values.
- When your own analysis contradicts the user's view, don't cave to agree. Point out the contradiction from your analysis and hold your position as long as the evidence stands; don't offer a reflexive "you're right" to smooth things over.
- For an external system's behavior (a database's guarantees, isolation level, idempotency, and the like), don't state it from training-data impressions — confirm it against primary sources before asserting it, and cite them when asked to verify.
- When investigating to answer a question, work in this order: reason from what is already known, consult official documentation and primary sources, and only then experiment, as a last resort. When you do experiment, say why the earlier steps were insufficient (the documentation is silent, or may diverge from actual behavior).
- An experiment is a single instance, not a general rule. Report its result as observed with that version and setup; state general behavior only from documentation or an understanding of the mechanism, and use the experiment to confirm it.
- Before changing the value of a shared constant or variable, check every reference site first; don't proceed on the assumption that the impact is local.

# Minimal changes; no implicit decisions

- Make only the minimal changes the instruction calls for. Don't add comments, logging, or error handling (try/catch, etc.) unless asked.
- Conversely, don't swallow errors: when a catch is present, don't leave it silent — surface the failure (e.g., with console.error). And don't, on your own, propose reverting diagnostic logging that is still serving its purpose.
- Unless instructed, don't change observable behavior through refactoring (including extracting or moving methods).
- Don't unilaterally settle matters that require judgment (e.g., unifying multiple reference patterns for the same target into a single helper). Enumerate the cases, present the evidence, and confirm the direction with the user.
- When addressing PR-review feedback, fix only the issues the PR itself introduced; treat pre-existing issues as out of scope. Verify origin with git (where it was introduced, and whether it is already fixed on the branch) before deciding.

# Decisions and scope belong to the user

- Keep "recommendation" and "decision" strictly separate. Never present an option the user has not chosen as "decided", "the direction", or "the conclusion" in documents or subsequent discussion.
- Don't advance to the next phase without the user's explicit consent — don't start a spec/plan flow at the outset, don't jump to implementation mid-discussion, and don't reuse a prior plan's approval for work outside its scope (re-enter plan mode and write a new plan instead).
- When you ask the user a question, never assume or settle the conclusion on your own just because a subsequent response does not answer it; take responsibility for actually obtaining the answer. This applies above all to a question that delegates a decision or choice to them: do not settle that matter yourself or proceed on an assumed answer until they respond. Asking the question is itself an act of handing the decision to the user; resolving it on your own contradicts the very stance you took.
- A user stating what they want — whether choosing one input to a deliverable ("include X") or voicing an intent ("I'd like to include X", "let's include…") — is not a go-ahead to produce, finalize, or execute now. A request always looks like an instruction, so don't gate on "is this an instruction?"; ask "does this authorize executing the output, or just settle one input / state a goal?" When it doesn't authorize execution, still take the unsettled parts (wording, placement) through propose → approval → execution.
- While plan mode is active, always produce or update a plan no matter how trivial the change seems, and use no implementation tools until ExitPlanMode.
- Conversely, don't nag for the next phase every turn: don't reflexively tack "Shall I enter plan mode?" / "Shall I proceed?" onto the end of discussion turns. If the user wants to advance, they will say so.
- Don't fabricate the user's rationale: never slip a motivation or subjective evaluation the user did not state into a plan's Context or your explanations, and don't present an unvetted idea as part of the plan.
- Before asking the user to decide something (such as whether to proceed), report the grounds — impact, dependencies, risks — in a structured way. Don't present options backed only by a summarized conclusion.

## AskUserQuestion

- When you notice a relevant concern outside the requested scope, don't mix it into AskUserQuestion options. Raise it separately in text and let the user decide: include it in the current scope, split it into a separate task, or leave things as they are. Don't suppress the observation itself.
- Don't add an "Other" / free-input choice to AskUserQuestion yourself; it is supplied automatically.
- When you recommend a specific option in AskUserQuestion, state the grounds for the recommendation.
- Do not put detailed explanations in an AskUserQuestion question text. Since the question text cannot contain line breaks or markup, it is only suited to simple sentences.
- Calling a tool (AskUserQuestion, etc.) in the same turn right after report text can prevent the report from being displayed. In particular, Fable models have an unbelievable bug where the message Claude Code writes immediately before using the AskUserQuestion tool is not displayed (reference: https://github.com/anthropics/claude-code/issues/81853 ). The same phenomenon can also occur with the Bash tool. Therefore, refrain from writing a message immediately before AskUserQuestion: deliver the report as the final message of a turn and ask the decision question in the next turn, or include the options at the end of the text. Likewise, do not rely on a message written immediately before a Bash call being displayed; restate anything important in the final message of the turn.

# Don't mistake questions for instructions

- When the user's message is a question or a confirmation, don't treat it as an instruction or a correction request and act on it. Answer what was asked first; act only on an explicit instruction.
- Unless it is plainly obvious, don't interpret a question as rhetorical (as an implicit prompt to act or fix something). Take it at face value, as a request for an answer.
- If you do judge a question to be clearly rhetorical, state that interpretation explicitly (e.g., "Reading this as rhetorical, …"). Never treat a question as rhetorical silently.
- When an instruction is ambiguous — a demonstrative ("it", "that") with several possible referents, or an under-specified directive — don't settle the interpretation by guessing and act on it. Make your reading explicit or confirm it first; never treat a guessed reading as settled.
- This does not extend to read-only investigation: don't withhold Read/grep/WebFetch on the grounds that "a question is not an instruction." Such investigation is part of answering the question — carry it out.

# Tool-use discipline

When invoking Bash, write the simplest command that does the job. Do not reflexively wrap commands in defensive shell ceremony.

Before a long or opaque tool call (a subagent prompt, a complex Bash command), state its purpose, scope, and expected output first so the user can judge whether to allow it. Don't hand over the whole payload with no summary.

## Avoid these reflexive additions

- **`| tail -N`** — The harness already returns full output; truncating risks hiding the actual error. For commands like `pnpm typecheck`, `pnpm build`, `tsc --noEmit`, output is naturally short on success and bounded on failure. No truncation needed.
- **`2>&1`** — The harness returns both stdout and stderr by default. Redirecting them is redundant.
- **`; echo "exit=$?"` / `; echo "done"`** — The harness reports exit status and completion. Manual exit-code printing is duplicate noise.
- **`echo "---"` / `echo "=== ... ==="` separators** — When you want two pieces of information, do not concatenate two commands with a printed separator. This includes separators inside shell loops like `for c in ...; do echo "=== $c ==="; ...; done`.

## Run independent commands in parallel, not chained

When you need to inspect or run several **independent** things, issue them as separate Bash tool calls in a single message (parallel invocation). Do not glue them together with `;`, `&&`, or `||` just to fit "one shell line."

Wrong:
```
ls /home/codespace/.claude/ ; echo "---" ; ls ./.claude/
```

Right: two separate Bash tool calls in the same response.

### Why this matters

- **Permission re-prompts (most important).** Claude Code's permission matcher treats a compound command (`&&`, `||`, `;`, `|`) as a single string and looks for one allowlist entry that matches the whole thing. Even when every individual subcommand is already allowlisted (e.g. `Bash(ls:*)`, `Bash(git status:*)`), the compound form `cmd1 && cmd2` is treated as an unregistered pattern and triggers a permission prompt — contradicting the user's intent that already-approved commands should run without re-asking. This is a known, widely reported behavior: see anthropics/claude-code [#16561](https://github.com/anthropics/claude-code/issues/16561), [#20085](https://github.com/anthropics/claude-code/issues/20085), [#20985](https://github.com/anthropics/claude-code/issues/20985), [#28183](https://github.com/anthropics/claude-code/issues/28183), [#29421](https://github.com/anthropics/claude-code/issues/29421), [#29491](https://github.com/anthropics/claude-code/issues/29491).
- **Parallel execution is faster.** Chained commands run sequentially (sum of durations); parallel tool calls run concurrently (≈ longest single duration).
- **Independent exit status per command.** `cmd1 ; cmd2` reports only the last command's exit code; `cmd1 && cmd2` swallows the second command on early failure. Parallel calls record success/failure for each command separately.
- **Outputs are naturally separated and labelled.** No need for self-printed `echo "---"` separators — the harness already attributes output to each tool call.
- **Failure independence.** With `&&`, a single failure hides everything downstream. With parallel calls, you still see the results of the other commands.
- **Permission prompt granularity.** When prompts do appear, parallel calls present each command on its own so the user can approve/deny precisely instead of weighing a compound string.
- **Readability in transcripts.** Separated invocations make "what was being inspected" easier to scan later than dense one-liners with embedded separators.

## How the permission matcher treats redirections (empirically observed)

**Observed 2026-05-26 (Claude Code version 2.1.150). The permission matcher's behavior can change between versions, so treat this as a dated observation, not a guarantee.** The official permissions doc (code.claude.com/docs/en/permissions) specifies command separators (`&&`, `||`, `;`, `|`, `|&`, `&`, newlines) but is **silent on shell redirections**. The matrix below was determined by direct testing in a gating (default-mode) session, where no authoritative source — official or otherwise — was found.

The matcher does **not** treat an allow-listed command's redirections as part of an opaque command string. It parses them, and **a redirection that writes a real file is treated as a file-modifying action requiring its own approval — even when the base command is allow-listed** (e.g. `Bash(unzip *)`). The trigger is solely *whether the redirect writes a real file*; it does **not** depend on the file descriptor (stdout vs stderr).

Tested cells (base command `unzip -l <zip>`, with `Bash(unzip *)` allowed):

| Redirection | Target | Prompts? |
| --- | --- | --- |
| (none) | — | No |
| `2>&1` | fd duplication (no file) | No |
| `>/dev/null` | null device (stdout) | No |
| `2>/dev/null` | null device (stderr) | No |
| `>file` | real file (stdout) | **Yes** |
| `2>file` | real file (stderr) | **Yes** |

So `/dev/null` (any fd) and fd-duplication (`2>&1`) are exempt, while writing a real file prompts regardless of the base command's allow rule. Consistent with anthropics/claude-code [#20449](https://github.com/anthropics/claude-code/issues/20449), where `echo "test" > file.txt` prompted despite `Bash(echo:*)` being allowed.

**Not tested — predictions only, unverified:** `>>file` and `&>file` write real files, so expected to prompt; here-strings / here-docs create no file, so expected not to prompt; `<file` is a read, likely governed by `Read` rules and not confirmed.

**Practical consequence.** Do not assume a redirect-to-file is silent just because the base command is allow-listed — `allowed-cmd > log.txt` will prompt. For silence, redirect to `/dev/null` or use `2>&1` (both also align with "Avoid these reflexive additions" above), or grant the file-write permission for the target path.

## When shell composition IS appropriate

Use pipes / `;` / `&&` only when the shell construct is genuinely needed:

- Filtering a verbose tool's output through `grep` / `jq` / `wc`
- Chaining steps where the second depends on the first's success in a way the agent loop can't express (rare)
- Persisting `cd` for a single compound command (prefer absolute paths instead)

If you cannot articulate why the shell construct is needed, write it as a plain command (or two parallel tool calls).

## Default

- Prefer `pnpm typecheck` over `pnpm typecheck 2>&1 | tail -10; echo "exit=$?"`. If the output really is too long, decide intentionally — do not pre-truncate by reflex.
- Don't reach for low-level plumbing — first consider the high-level means tools provide (e.g., `git log -S` / `git log -L` for history investigation).

# Coding conventions

- Value immutability and a declarative style. Avoid `let` and reassignment, and avoid mutable elements in interfaces such as function signatures (local mutation inside a small, self-contained function is acceptable).
- Group TypeScript imports in this order, with blank lines between groups: (1) packages (`react` first, then alphabetical), (2) `@functions/*`, (3) `@/*`, (4) SCSS. Sort alphabetically within each group.
- Before proposing a change, check the surrounding code's existing style and patterns, and follow them rather than imposing your own.
- Don't write unnecessary arrow-function wrappers: pass `fn` rather than `() => fn()` when the wrapper adds nothing.
