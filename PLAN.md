# Termux Sandbox Plan

## High Level Plan
1. Finish feature development
2. Refactor/clean up - GitHub-ready
3. Make termux-sandbox into a package, while asb stays just a standalone script

## NEXT
- Add additional sandbox management features to `asb`:
  - list
  - delete
  - reset
  - copy
  - take snapshot
  - revert to snapshot

## Done
- ✅ Relay argument handling no longer uses `eval`
- ✅ `asb` computes `SCRIPT_DIR` near the top of the script
- ✅ PATH overlay for relay client
- ✅ Removed redundant server-side relay cleanup
- ✅ Removed double `cleanup_relay` call
- ✅ Added `--kill-on-exit` to proot
- ✅ Split tests into build (slow) and runtime (fast) categories with shared cache
- ✅ Refactored `termux-sandbox` internals into a shared helper library (`scripts/termux-sandbox-lib.sh`)

## FUTURE
Out-of-scope ideas
- Shell integration (auto‑set title or terminal badge)
