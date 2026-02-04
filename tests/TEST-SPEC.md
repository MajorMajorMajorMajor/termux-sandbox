# Test Harness Spec (Shell)

## Goals
- One test per module/script.
- Tests default to temporary directories; allow overrides.
- Tests clean up on success unless `--keep` is set.
- Tests emit verbose diagnostics (what they are doing, paths, commands).
- Each test exits `0` on pass and non-zero on failure.
- Integration runner executes all tests in order, reuses artifacts where possible.

## Directory layout
```
tests/
  README.md
  run-all.sh
  helpers.sh
  test-apply-symlinks.sh
  test-extract-bootstrap.sh
  test-proot.sh
  test-asb.sh
```

## Common conventions
- `set -euo pipefail`
- `ROOTFS`/`WORKDIR` default to `mktemp -d`, override via `--rootfs`, `--workdir`.
- `--keep` prevents cleanup; otherwise `trap cleanup EXIT`.
- `--verbose` (default on) prints `log` lines.
- Each script prints:
  - start banner
  - paths used
  - commands executed
  - `PASS` or `FAIL` at end

## Shared helper: `tests/helpers.sh`
Functions:
- `log()`, `die()`
- `mktemp_dir()` returns temp dir
- `cleanup()` removes temp dirs unless `KEEP=1`
- `require_cmd()`
- `print_paths()` standard format
- `pass()` / `fail()` messages

## Individual tests
1) **test-extract-bootstrap.sh**
   - Calls `scripts/extract-bootstrap.sh` with `ROOTFS`
   - Verifies `$ROOTFS/bin/bash` exists
   - Verifies `$ROOTFS/SYMLINKS.txt` exists
   - PASS/FAIL accordingly

2) **test-apply-symlinks.sh**
   - Depends on extracted rootfs
   - Runs `scripts/apply-symlinks.sh`
   - Verifies `$ROOTFS/bin/chmod` symlink exists
   - PASS/FAIL

3) **test-proot.sh**
   - Uses `ROOTFS` + `WORKDIR`
   - Runs a non-interactive proot command that prints `id`, `pwd`, `ls`
   - FAIL if proot command exits non-zero

4) **test-asb.sh**
   - Ensures `asb --rootfs-path` and `--workdir-path` return valid paths
   - Optionally checks prompt behavior (non-interactive mode should fail gracefully)
   - Should not bootstrap unless explicitly told

## Integration runner: `tests/run-all.sh`
- Calls tests in dependency order:
  1. extract-bootstrap
  2. apply-symlinks
  3. proot
  4. asb
- Reuses a shared rootfs/workdir:
  - `ROOTFS_CACHE` and `WORKDIR_CACHE` in temp or `--rootfs/--workdir`
- If cache exists, skip extraction
- Produces a summary at the end:
  - List of tests with PASS/FAIL
  - Non-zero exit if any fail

## Best practice notes for README
- Avoid hardcoded `$HOME` paths in tests.
- Allow overriding paths/env.
- Use `trap` to cleanup.
- Tests should be deterministic and safe to re-run.
