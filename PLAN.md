# Termux Sandbox Plan

## High Level Plan
1. Fix relay issues (see ISSUES.md)
2. Finish feature development
3. Refactor/clean up - GitHub-ready
4. Make termux-sandbox into a package, while asb stays just a standalone script

## NEXT — Fix relay issues
The host-side `am` relay works but has problems. Priority order:
1. ~~**Stop clobbering `$ROOTFS/bin/am`**~~ ✅ Done — uses PATH overlay now
2. **Remove `eval` from relay server** — use null-delimited args (ISSUES.md #2)
3. ~~**Remove double cleanup** and **let client own its request dir**~~ ✅ Done
4. **Move `SCRIPT_DIR` to top of `asb`** (ISSUES.md #7)

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
