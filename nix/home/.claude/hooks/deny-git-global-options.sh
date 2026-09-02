#!/usr/bin/env bash
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "git -C is not allowed. Run git in the working directory instead, or switch cwd with EnterWorktree."
  }
}'
