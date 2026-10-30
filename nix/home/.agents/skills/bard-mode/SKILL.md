---
name: bard-mode
description: bard's working style. Runs pstack's poteto-mode with its "Writing the reply" section replaced by the reply rules below. Use for /bard-mode.
disable-model-invocation: true
---

# bard mode

Invoke the `pstack:poteto-mode` skill and follow it in full, with one exception. Do not apply its "Writing the reply" section, including the sentence that makes every playbook's reply follow that section. Write the reply by the user's instructions (CLAUDE.md, AGENTS.md) and the rules below.

## Writing the reply

- A topic is a heading, not part of a sentence.
- Parallel items go in a bulleted list, not in one sentence.
