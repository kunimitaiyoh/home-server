# Plan mode

- While plan mode is active, always produce or update a plan no matter how trivial the change seems, and use no implementation tools until ExitPlanMode.

# AskUserQuestion

- Don't add an "Other" / free-input choice to AskUserQuestion yourself; it is supplied automatically.
- Do not put detailed explanations in an AskUserQuestion question text. Since the question text cannot contain line breaks or markup, it is only suited to simple sentences.
- Calling a tool (AskUserQuestion, etc.) in the same turn right after report text can prevent the report from being displayed. In particular, Fable models have an unbelievable bug where the message Claude Code writes immediately before using the AskUserQuestion tool is not displayed (reference: https://github.com/anthropics/claude-code/issues/81853 ). The same phenomenon can also occur with the Bash tool. Therefore, refrain from writing a message immediately before AskUserQuestion: deliver the report as the final message of a turn and ask the decision question in the next turn, or include the options at the end of the text. Likewise, do not rely on a message written immediately before a Bash call being displayed; restate anything important in the final message of the turn.

# Tool output

- **`| tail -N`** — The harness already returns full output; truncating risks hiding the actual error. For commands like `pnpm typecheck`, `pnpm build`, `tsc --noEmit`, output is naturally short on success and bounded on failure. No truncation needed.
- **`2>&1`** — The harness returns both stdout and stderr by default. Redirecting them is redundant.
- **`; echo "exit=$?"` / `; echo "done"`** — The harness reports exit status and completion. Manual exit-code printing is duplicate noise.

# Command permissions

- **Permission re-prompts (most important).** Claude Code's permission matcher treats a compound command (`&&`, `||`, `;`, `|`) as a single string and looks for one allowlist entry that matches the whole thing. Even when every individual subcommand is already allowlisted (e.g. `Bash(ls:*)`, `Bash(git status:*)`), the compound form `cmd1 && cmd2` is treated as an unregistered pattern and triggers a permission prompt — contradicting the user's intent that already-approved commands should run without re-asking. This is a known, widely reported behavior: see anthropics/claude-code [#16561](https://github.com/anthropics/claude-code/issues/16561), [#20085](https://github.com/anthropics/claude-code/issues/20085), [#20985](https://github.com/anthropics/claude-code/issues/20985), [#28183](https://github.com/anthropics/claude-code/issues/28183), [#29421](https://github.com/anthropics/claude-code/issues/29421), [#29491](https://github.com/anthropics/claude-code/issues/29491).

# How the permission matcher treats redirections (empirically observed)

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

**Practical consequence.** Do not assume a redirect-to-file is silent just because the base command is allow-listed — `allowed-cmd > log.txt` will prompt. For silence, redirect to `/dev/null` or use `2>&1` (both also align with "Tool output" above), or grant the file-write permission for the target path.
