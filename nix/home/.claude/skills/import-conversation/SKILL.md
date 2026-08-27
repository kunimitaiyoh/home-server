---
name: import-conversation
description: Resume a Claude Code conversation that was running on another machine, using a transcript produced there by the `/export` slash command. Use when the user supplies the exported file and wants to continue in full context. Invocation form `/import-conversation <path-to-export-file>`.
---

# Import Conversation From Another Machine

Continue a Claude Code session that was running on a different machine by ingesting the markdown transcript that session produced via `/export <file>`. Claude Code has no built-in cross-machine resume, so the only path is to read the export, reconstruct prior state in this session's context, and pick up from where the other machine left off.

## Inputs

- One argument: the path (absolute or relative to the current working directory) to the exported markdown file.
- If no path was supplied, ask the user for it before doing anything else.

## Process

1. Read the entire export file with the Read tool. Do not skim — every message and tool result may carry context that changes what to do next. If the file is very long, read it in one pass and summarize internally rather than re-reading it repeatedly.
2. Build an internal model of the previous session:
   - The user's original request and end goal.
   - Decisions and conventions adopted along the way (libraries, naming, file layout, command choices).
   - Every file the previous session created or modified, and the final intended state of each.
   - What was completed versus what was still in progress when the export was taken.
   - The exact next step the previous session was about to perform.
3. Reconcile the export with the current machine before acting:
   - Absolute paths and tool results in the export reflect the other machine's filesystem. They may not resolve here. Treat them as descriptions, not facts.
   - For each file the export expects to have modified, verify it exists in the current working directory and read its live contents. Note any divergence between what the export expects and what is actually present.
   - If the export references a specific git branch, confirm the current branch matches; warn the user if it does not.
   - If referenced external resources (environment variables, services, credentials) are not obviously available here, surface that.
4. Report back to the user in 5–10 lines:
   - What the previous session was doing and how far it got.
   - Any divergence found between the export's expectations and this machine's state.
   - The proposed next step.
5. Wait for the user's confirmation before resuming the work. Do not silently start editing files based solely on intent inferred from the export.

## Caveats

- The export is rendered prose, not a structured session dump. Tool inputs and outputs appear as readable text and may have been truncated for display. Reconstruct intent from surrounding context rather than treating any single line as authoritative.
- File contents shown inside the export are snapshots from the other machine. Always re-read the live file with the Read tool before editing it on this machine.
- Do not attempt to re-execute every tool call from the export. Many of them already produced their effect on the other machine (or on shared state like git). Replay only what the current machine still needs.
