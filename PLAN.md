# Termux Sandbox Plan

## High Level Plan
1. Test that all the optional features work
2. Refactor/clean up - GitHub-ready
3. Make termux-sandbox into a package, while asb stays just a standalone script

## TODO
- Add default, coloured prompt indicators so when you switch to a sandbox shell you always know which one you're in

## Done
- Reworked tests using the spec in tests/

## FUTURE
Out-of-scope ideas
- Add additional sandbox management features to `asb`: list, delete, recreate, copy, take snapshot, revert to snapshot
- Replace manual installation steps in the readme with an editable makefile
- Shell integration (auto‑set title or terminal
 badge)
