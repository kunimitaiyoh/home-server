# Bash command style

When invoking Bash, write the simplest command that does the job. Do not reflexively wrap commands in defensive shell ceremony.

## Avoid these reflexive additions

- **`| tail -N`** — The harness already returns full output; truncating risks hiding the actual error. For commands like `pnpm typecheck`, `pnpm build`, `tsc --noEmit`, output is naturally short on success and bounded on failure. No truncation needed.
- **`2>&1`** — The harness returns both stdout and stderr by default. Redirecting them is redundant.
- **`; echo "exit=$?"` / `; echo "done"`** — The harness reports exit status and completion. Manual exit-code printing is duplicate noise.
- **`echo "---"` separators** — When you want two pieces of information, do not concatenate two commands with a printed separator.

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

Prefer `pnpm typecheck` over `pnpm typecheck 2>&1 | tail -10; echo "exit=$?"`. If the output really is too long, decide intentionally — do not pre-truncate by reflex.
