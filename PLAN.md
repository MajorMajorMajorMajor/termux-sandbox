# Termux Sandbox Plan

## Goals
- Rename and generalize the existing `agent-termux` workflow into a reusable sandbox system.
- Support multiple sandboxes by name (e.g., `agent-sandbox-0`, `agent-sandbox-test`).
- Provide a wrapper command `asb` to manage/launch sandboxes, including first-time bootstrap.
- Store the project in shared storage for persistence: `/storage/emulated/0/code/termux-sandbox`.

## Proposed Layout
- Project root: `/storage/emulated/0/code/termux-sandbox/`
- Scripts:
  - `termux-sandbox` (main launcher, installable into a user bin dir)
  - `asb` (wrapper command to pick sandbox by name)
- Sandbox root dir:
  - Base: `$HOME/sandboxes/`
  - Each sandbox: `$HOME/sandboxes/agent-sandbox-<name>`
- Workdir:
  - `$HOME/agent-work-<name>` mapped into `/data/data/com.termux/files/usr/home/agent/work`

## Naming Changes
- Old script: `agent-termux` → new main script: `termux-sandbox`
- Old rootfs: `sandboxes/termux-agent` → `sandboxes/agent-sandbox-<name>`
- Wrapper: `asb <name>`
  - Example: `asb 0` → `agent-sandbox-0`
  - Example: `asb test` → `agent-sandbox-test`

## Behavior
- `asb <name>` resolves sandbox name and calls `termux-sandbox <name>`.
- `termux-sandbox <name>`:
  - Ensures rootfs directories exist.
  - Ensures work dir exists.
  - Ensures any required symlinks/dirs exist inside rootfs (e.g., `home/agent/work`).
  - Runs `proot` without `PROOT_NO_SECCOMP=1` to avoid `cd` failures.
  - Sets `HOME`, `PREFIX`, and `PATH` as in current script.

## Bootstrapping
- First run should create:
  - `$HOME/sandboxes/agent-sandbox-<name>/home/agent/work`
  - `$HOME/sandboxes/agent-sandbox-<name>/etc/dpkg/dpkg.cfg.d`
  - `$HOME/agent-work-<name>`
- No extra system setup required beyond `proot` being installed.

## Install Location
- Install `termux-sandbox` and `asb` into `$HOME/bin` (user-scoped).
- Ensure `$HOME/bin` is on `PATH` (via `~/.bashrc`).

## Steps to Implement
1. Copy current `agent-termux` into the project as a reference baseline.
2. Create `termux-sandbox` script from `agent-termux`, parameterized by sandbox name.
3. Create `asb` wrapper script to parse name and dispatch to `termux-sandbox`.
4. Add basic checks for `proot` availability and print a clear error if missing.
5. Update existing `agent-termux` users to the new commands or provide a compatibility shim.
6. Document usage in `README.md` (optional, after scripts are in place).

## Open Questions
- Should `asb` accept a default name if none provided (e.g., `0`)?
- Should we keep a compatibility `agent-termux` shim?
