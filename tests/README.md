# Tests

Tests are split into two categories:

## Build tests (slow)

Test rootfs setup — extraction and symlink creation. These always work against
fresh temporary directories.

- `test-extract-bootstrap.sh` — extract bootstrap from Termux APK
- `test-apply-symlinks.sh` — apply SYMLINKS.txt to an extracted rootfs

Run them with:

```sh
./tests/run-build.sh
```

## Runtime tests (fast)

Test sandbox operation against an existing rootfs. These use a shared cache
in `$TMPDIR/termux-sandbox-test-cache/` so they skip the ~30s bootstrap step
on repeat runs.

- `test-proot.sh` — proot launch and shebang compatibility
- `test-relay.sh` — host-side `am` relay via proot
- `test-relay-hup.sh` — relay survives `SIGHUP` and still serves `am`
- `test-asb.sh` — `asb` wrapper path resolution and error handling

Run them with:

```sh
./tests/run-runtime.sh
```

## Run everything

```sh
./tests/run-all.sh
```

This runs build tests first (with a shared temp rootfs), then runtime tests
against the same rootfs. No cache is used — each run bootstraps from scratch.

## Common options

All runners and individual tests accept:

- `--rootfs DIR` / `--workdir DIR` — override paths
- `--keep` — keep temporary directories after the run
- `--quiet` — suppress verbose logs

## Run individual tests

```sh
./tests/test-extract-bootstrap.sh
./tests/test-apply-symlinks.sh
./tests/test-proot.sh
./tests/test-relay.sh
./tests/test-relay-hup.sh
./tests/test-asb.sh
```

Runtime tests (`test-proot.sh`, `test-relay.sh`, `test-relay-hup.sh`) use the
shared cache when run standalone. Build tests always use fresh temporary
directories.

### test-asb

`test-asb.sh` runs with a temporary `HOME` so it does not touch real sandboxes.
Override the sandbox name with `--name` or `ASB_NAME`:

```sh
ASB_NAME=dev ./tests/test-asb.sh
./tests/test-asb.sh --name dev
```
