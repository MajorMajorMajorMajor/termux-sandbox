# termux-sandbox

A general-purpose CLI to create and run named Termux sandboxes using `proot`.

## Usage
```sh
termux-sandbox <name> [options]
```

`<name>` is required and identifies the sandbox rootfs and workdir. Only one name
argument is accepted; any additional non-option arguments are treated as errors.

## Concepts
- **sandbox**: a named rootfs + workdir pair.
- **rootfs**: the isolated filesystem used by the sandbox.
- **workdir**: the bind-mounted workspace directory.

## Behavior
- Requires `proot` to be installed.
- Default paths:
  - Rootfs: `$HOME/sandboxes/<name>`
  - Workdir: `$HOME/agent-work-<short-name>` where `<short-name>` is `<name>`
    without the `agent-sandbox-` prefix (if present).
- If the rootfs is missing `bin/bash`, the sandbox is bootstrapped using the
  selected bootstrap mode (default: `termux`).
- Prints a startup summary before launch (rootfs, workdir, storage mode, scoped paths).
- When launched via `asb` with a saved storage policy, startup output also shows
  the policy preset and policy file path.
- After bootstrapping, Termux symlinks are applied and a prompt marker is
  written to `/etc/termux-sandbox-rc` inside the rootfs.
- Helper scripts are resolved from either:
  - `scripts/` next to the `termux-sandbox` launcher
  - `$HOME/.termux-sandbox/scripts`
- Storage access defaults to `none`.
  - `--storage=none` masks `/storage/emulated` (no shared storage visible).
  - `--storage=full` binds `/storage/emulated` into the sandbox.
  - `--storage=scoped` masks `/storage/emulated` first, then binds only selected `--storage-path` entries.
  - Scoped paths are relative to `/storage/emulated` and keep the same in-sandbox layout.

## Options
- `--bootstrap[=MODE]`: Bootstrap mode: `termux` (default), `prefix`, `mirror`,
  `url`, `file`.
- `--bootstrap-url URL`: Download bootstrap zip from URL (implies `url` mode).
- `--bootstrap-file PATH`: Use an existing bootstrap zip file (implies `file` mode).
- `--no-bootstrap`: Do not bootstrap; error if the rootfs is missing `bin/bash`.
- `--rootfs DIR`: Override the rootfs location.
- `--workdir DIR`: Override the workdir location.
- `--storage MODE`: Android storage access: `none` (default), `scoped`, `full`.
- `--storage-path RELPATH`: Path under `/storage/emulated` (repeatable, implies `scoped`).
- `-h, --help`: Show help.

## Examples
```sh
termux-sandbox agent-sandbox-test
termux-sandbox agent-sandbox-test --bootstrap=prefix
termux-sandbox agent-sandbox-test --bootstrap-url https://example.com/bootstrap.zip
termux-sandbox agent-sandbox-test --rootfs /tmp/rootfs --workdir /tmp/workdir
termux-sandbox agent-sandbox-test --storage=full
termux-sandbox agent-sandbox-test --storage=scoped --storage-path 0/Downloads --storage-path 0/Documents
```
