# Termux Sandbox Plan

## High Level Plan
1. Refactor/clean up - GitHub-ready
2. Finish feature development

## NEXT
- Security and robustness review (remaining):
  - audit scripts for quoting/temp-dir/path safety
  - verify timeout/failure handling and safe defaults
  - full security and code correctness analysis

## FUTURE (out of scope)
- Add command-oriented sandbox management to `termux-sandbox`:
  - `create <name>`
  - `rm <name>`
  - `list`
  - `info <name>`
- Add command-oriented wrappers to `asb`:
  - `list`
  - `delete`
  - `reset`
  - `copy`
  - `snapshot`
  - `revert`
- Add non-interactive command execution mode for `termux-sandbox` (`run <name> [command...]`)
- Shell integration (auto-set title or terminal badge)
