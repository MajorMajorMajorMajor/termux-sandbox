# Termux Sandbox Plan

## High Level Plan
1. Finish feature development
2. Refactor/clean up - GitHub-ready
3. Make termux-sandbox into a package, while asb stays just a standalone script

## NEXT
- Add repo distribution essentials (license, contribution docs, release notes)
- Add lint/quality checks for public GitHub use

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
