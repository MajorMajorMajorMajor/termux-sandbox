# Termux Sandbox Plan

## High Level Plan
1. Get basic functionality to work
2. Test that all the optional features work
3. Make termux-sandbox into a package, while asb stays just a standalone script

## TODO
- Diagnose the bootstrap hang after extraction (proot/second-stage behavior).
- Ensure helper scripts are installed and discoverable consistently.
- Decide how to handle `SYMLINKS.txt` application for existing rootfs.
- Add a simple test/diagnostic README section for `tests/` utilities.
- Publish to GitHub with finalized documentation.

## ROADMAP
1. Replace manual installation steps in the readme with an editable makefile
2. Add default, coloured prompt indicators so when you switch to a sandbox shell you always know which one you're in
