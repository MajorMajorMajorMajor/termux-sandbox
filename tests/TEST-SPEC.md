# Test Harness Spec (Shell)

## Goals
- One test per module/script.
- Tests default to temporary directories; allow overrides.
- Tests clean up on success unless `--keep` is set.
- Tests emit verbose diagnostics (what they are doing, paths, commands).
- Each test exits `0` on pass and non-zero on failure.
- Build and runtime tests are clearly separated.

## Test categories

### Build tests (slow)
Test rootfs setup. Always use fresh temporary directories — never a cache —
because their purpose is to verify the setup process itself.

1. **test-extract-bootstrap.sh** — extract bootstrap from Termux APK
2. **test-apply-symlinks.sh** — apply SYMLINKS.txt to an extracted rootfs

### Runtime tests (fast)
Test sandbox operation against an existing rootfs. Use a shared cache in
`$TMPDIR/termux-sandbox-test-cache/` by default so they skip the ~30s
bootstrap on repeat runs.

3. **test-proot.sh** — proot launch, basic commands, shebang compatibility
4. **test-relay.sh** — host-side `am` relay via proot
5. **test-relay-hup.sh** — relay survives `SIGHUP` and still serves `am`
6. **test-asb.sh** — `asb` wrapper path resolution and error handling

## Directory layout
```
tests/
  README.md
  TEST-SPEC.md
  helpers.sh
  run-all.sh           # all tests, fresh rootfs
  run-build.sh         # build tests only
  run-runtime.sh       # runtime tests only, uses cache
  test-extract-bootstrap.sh
  test-apply-symlinks.sh
  test-proot.sh
  test-relay.sh
  test-relay-hup.sh
  test-asb.sh
```

## Common conventions
- `set -euo pipefail`
- `ROOTFS`/`WORKDIR` default to `mktemp -d` (build) or `cached_rootfs` (runtime), override via `--rootfs`, `--workdir`.
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
- `mktemp_dir()` returns temp dir (added to cleanup list)
- `cached_rootfs()` returns a persistent cache dir, bootstrapping if needed
- `cleanup()` removes temp dirs unless `KEEP=1`
- `require_cmd()`
- `print_paths()` standard format
- `pass()` / `fail()` messages
- `timer_start()` / `timer_elapsed_ms()` / `format_duration_ms()`

## Runners

### run-all.sh
- Creates fresh temp rootfs and workdir
- Runs build tests first, then runtime tests against the same rootfs
- Produces a summary at the end

### run-build.sh
- Creates fresh temp rootfs
- Runs build tests only
- Useful for testing bootstrap/symlink changes

### run-runtime.sh
- Uses `cached_rootfs()` for fast startup
- Runs runtime tests only
- Useful for quick iteration on proot/relay/asb changes

## Best practice notes
- Avoid hardcoded `$HOME` paths in tests.
- Allow overriding paths/env.
- Use `trap` to cleanup.
- Tests should be deterministic and safe to re-run.
- Runtime tests must not modify the rootfs in ways that affect other tests.
