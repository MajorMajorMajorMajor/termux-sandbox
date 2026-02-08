# Termux Sandbox Plan

## High Level Plan
1. Finish feature development
2. Refactor/clean up - GitHub-ready
3. Make termux-sandbox into a package, while asb stays just a standalone script

## NEXT
- README polish for public GitHub users:
  - sharpen opening value proposition
  - add quickstart copy/paste install + first run
  - document requirements and limitations/non-goals
  - add troubleshooting and safety notes
- Release and versioning setup:
  - choose SemVer policy
  - create first tagged release (`v0.1.0` or `v1.0.0`)
  - add release notes template / changelog workflow
- Security and robustness review:
  - audit scripts for quoting/temp-dir/path safety
  - verify timeout/failure handling and safe defaults
  - document relay trust boundaries and security reporting path

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
