# Termux Sandbox Plan

## High Level Plan
1. Fix relay issues (see ISSUES.md)
2. Finish feature development
3. Refactor/clean up - GitHub-ready
4. Make termux-sandbox into a package, while asb stays just a standalone script

## NEXT — Fix relay issues
The host-side `am` relay works but has problems. Priority order:
1. **Remove `eval` from relay server** — use null-delimited args (ISSUES.md #1)
2. **Move `SCRIPT_DIR` to top of `asb`** (ISSUES.md #4)

## Done
- ✅ PATH overlay for relay client (ISSUES.md #1)
- ✅ Removed redundant server-side relay cleanup (ISSUES.md #5)
- ✅ Removed double `cleanup_relay` call (ISSUES.md #6)
- ✅ Added `--kill-on-exit` to proot
- ✅ Split tests into build (slow) and runtime (fast) categories with shared cache

## TODO
- Add additional sandbox management features to `asb`: 
    - list
	- delete
	- reset
	- copy
	- take snapshot
	- revert to snapshot

## FUTURE
Out-of-scope ideas
- Shell integration (auto‑set title or terminal badge)
