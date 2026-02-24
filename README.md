# Termux Sandbox

A lightweight Termux sandbox launcher for running multiple named sandboxes with `proot`.

`termux-sandbox` is the core tool. `asb` is a convenience wrapper for short-name workflows.

## Quickstart

```sh
git clone https://github.com/MajorMajorMajorMajor/termux-sandbox.git
cd termux-sandbox
make install
asb 0
```

Or with GitHub CLI:

```sh
gh repo clone MajorMajorMajorMajor/termux-sandbox
cd termux-sandbox
make install
asb 0
```

On first launch, the sandbox rootfs is bootstrapped automatically.

## How the tools fit together

- `termux-sandbox` resolves paths, bootstraps rootfs if needed, prepares the environment, and enters the sandbox with `proot`.
- `asb` expands short names (for example `0` -> `agent-sandbox-0`) and delegates to `termux-sandbox`.

## Requirements

- Android with Termux
- `proot`
- `unzip`
- `bash`
- Optional for URL bootstrap: `curl` or `wget`

Install missing dependencies in Termux:

```sh
pkg install proot unzip curl
```

## Default paths on host filesystem

- Rootfs: `$HOME/sandboxes/agent-sandbox-<name>`
- Workdir: `$HOME/agent-work-<name>`

## Install

```sh
make install
```

Optional overrides:

```sh
make install PREFIX="$HOME" BINDIR="$HOME/bin" SCRIPTS_DIR="$HOME/.termux-sandbox/scripts"
```

Uninstall:

```sh
make uninstall
```

Ensure `$HOME/bin` is on your `PATH` (for example by adding it to `~/.bashrc`).

`termux-sandbox` expects helper scripts (like `extract-bootstrap.sh`) to live in
`$HOME/.termux-sandbox/scripts` or `scripts/` next to the launcher.

## Usage

Launch a sandbox by short name:

```sh
asb 0
```

If no storage flags are passed and no per-sandbox storage policy exists, interactive `asb` will prompt for a storage preset (none, downloads, docs, media, full) and save it for future launches.

You can print paths for scripting:

```sh
asb 0 --workdir-path
asb 0 --rootfs-path
```

You can also invoke the launcher directly:

```sh
termux-sandbox agent-sandbox-test
```

Storage access examples:

```sh
termux-sandbox agent-sandbox-test --storage=none
termux-sandbox agent-sandbox-test --storage=full
termux-sandbox agent-sandbox-test --storage=scoped --storage-path 0/Downloads --storage-path 0/Documents
```

For scoped storage, paths are relative to `/storage/emulated` and are mounted to the same path inside the sandbox; other `/storage/emulated` paths are masked.

### `termux-sandbox` options

```sh
termux-sandbox <name> [options]
```

- `--bootstrap[=MODE]`: Bootstrap mode: `termux` (default), `prefix`, `mirror`, `url`, `file`.
- `--bootstrap-url URL`: Download bootstrap zip from URL (implies `url` mode).
- `--bootstrap-file PATH`: Use an existing bootstrap zip file (implies `file` mode).
- `--no-bootstrap`: Do not bootstrap; error if the rootfs is missing `bin/bash`.
- `--rootfs DIR`: Override the rootfs location.
- `--workdir DIR`: Override the workdir location.
- `--storage MODE`: Android storage access: `none` (default), `scoped`, `full`.
- `--storage-path RELPATH`: Path under `/storage/emulated` (repeatable, implies `scoped`).

## Safety notes and trust boundaries

- The relay feature can execute host-side `am` commands requested from inside the sandbox.
- The relay transport uses a shared directory under the sandbox rootfs and null-delimited arguments.
- Only run trusted commands/scripts inside sandboxes where relay is enabled.
- Do not treat the sandbox as a strict security boundary against a malicious workload.


## Tests

Run all tests:

```sh
./tests/run-all.sh
```

Run build-only tests:

```sh
./tests/run-build.sh
```

Run runtime-only tests:

```sh
./tests/run-runtime.sh
```

For test details and options, see `tests/README.md`.

## Documentation

- `docs/termux-sandbox.md` — full `termux-sandbox` behavior and options.
- `docs/asb.md` — full `asb` behavior, flags, and examples.

## Prompt colors

`termux-sandbox` prepends a colored `[sandbox-name]` marker to your prompt.
The palette is defined in `termux-sandbox` inside `write_prompt_rc()`:

```sh
TERMUX_SANDBOX_COLORS=(96 92 93 95 94 91 97)
```

You can adjust this list to your preference. The sandbox name is hashed into
this palette so each sandbox consistently uses one of the colors.
