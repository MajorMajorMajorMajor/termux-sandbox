# Tests

## Run all tests

```sh
./tests/run-all.sh
```

Common options:

- `--rootfs DIR` / `--workdir DIR`: reuse or override paths
- `--keep`: keep temporary directories after the run
- `--quiet`: suppress verbose logs

`run-all.sh` uses a shared rootfs/workdir cache and skips re-extraction when the
rootfs already contains `bin/bash`.

## Run individual tests

```sh
./tests/test-extract-bootstrap.sh
./tests/test-apply-symlinks.sh
./tests/test-proot.sh
./tests/test-asb.sh
```

All tests default to temporary directories and clean up on success unless
`--keep` is set.

### test-asb

`test-asb.sh` runs with a temporary `HOME` so it does not touch real sandboxes.
You can override the sandbox name with `--name` or `ASB_NAME`:

```sh
ASB_NAME=dev ./tests/test-asb.sh
./tests/test-asb.sh --name dev
```
