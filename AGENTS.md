# Termux Sandbox – Architecture Summary

## Core executables
- `termux-sandbox`: main launcher CLI.
  - Parses options (`--bootstrap`, `--rootfs`, `--workdir`, etc.).
  - Resolves rootfs/workdir defaults.
  - Sources shared logic from `scripts/termux-sandbox-lib.sh`.
  - Sets environment and launches sandbox via `proot`.
- `asb`: convenience wrapper.
  - Expands short names (`0` -> `agent-sandbox-0`).
  - Computes standard rootfs/workdir paths.
  - Supports `--rootfs-path` and `--workdir-path`.
  - Prompts in interactive mode before creating missing sandboxes.
  - Delegates execution to `termux-sandbox`.

## Shared library layer
- `scripts/termux-sandbox-lib.sh` centralizes reusable logic:
  - Bootstrap orchestration (`termux`, `prefix`, `mirror`, `url`, `file`, `none`).
  - Helper script discovery/execution.
  - Symlink application.
  - Rootfs preparation (`/tmp` and `/var/tmp` sticky permissions, base dirs).
  - Prompt RC generation (`/etc/termux-sandbox-rc`).
  - Relay setup/cleanup for host-side Android command execution (`am`).

## Helper scripts
- `scripts/extract-bootstrap.sh`: extracts bootstrap from Termux app/APK into rootfs.
- `scripts/apply-symlinks.sh`: applies links listed in `SYMLINKS.txt`.
- `scripts/sandbox-relay.sh`: host-side relay server; executes `am` and returns output/status.
- `scripts/sandbox-relay-client.sh`: in-sandbox client shim for `am` using null-delimited args.

## Build/install
- `Makefile` installs:
  - `termux-sandbox` and `asb` into `$(BINDIR)` (default: `$HOME/bin`).
  - helper scripts into `$(SCRIPTS_DIR)` (default: `$HOME/.termux-sandbox/scripts`).
- `make uninstall` removes installed binaries/scripts.

## Tests
- Harness: `tests/helpers.sh` (logging, temp/cache dirs, argument parsing, cleanup, timing).
- Runners:
  - `tests/run-build.sh` (slow setup/build tests)
  - `tests/run-runtime.sh` (fast runtime tests using cached rootfs)
  - `tests/run-all.sh` (fresh full run)
- Test split:
  - Build: `test-extract-bootstrap.sh`, `test-apply-symlinks.sh`
  - Runtime: `test-proot.sh`, `test-relay.sh`, `test-asb.sh`

## Docs
- `README.md`: overview, install, usage.
- `docs/termux-sandbox.md`: detailed `termux-sandbox` behavior/options.
- `docs/asb.md`: detailed `asb` behavior/options.
- `PLAN.md`: roadmap.

## End-to-end flow
1. User runs `asb <name>` or `termux-sandbox <name>`.
2. Name and paths are resolved.
3. Rootfs is bootstrapped if missing.
4. Symlinks and rootfs prep are applied; prompt RC is written.
5. Relay is optionally started and `am` shim is injected via PATH prepend.
6. `proot` starts with Termux-style env and bind mounts; shell starts in sandbox.
