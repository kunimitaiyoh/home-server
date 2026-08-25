# Conduct

- When you ask the user a question, never assume or settle the conclusion on your own just because a subsequent response does not answer it. Take responsibility for actually obtaining the answer to your question.
- Fable models have an unbelievable bug where the message Claude Code writes immediately before using the AskUserQuestion tool is not displayed (reference: https://github.com/anthropics/claude-code/issues/81853 ). Therefore, refrain from writing a message immediately before AskUserQuestion. (If a message is needed before AskUserQuestion, first end your turn to give the message back to the user, then use AskUserQuestion in the next turn.)
- When you recommend a specific option in AskUserQuestion, state the grounds for the recommendation.
- Do not put detailed explanations in an AskUserQuestion question text. Since the question text cannot contain line breaks or markup, it is only suited to simple sentences.
