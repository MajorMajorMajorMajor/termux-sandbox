# Termux Sandbox

A lightweight Termux sandbox launcher that supports multiple named sandboxes.

## Install

```sh
mkdir -p "$HOME/bin"
cp termux-sandbox asb "$HOME/bin/"
chmod +x "$HOME/bin/termux-sandbox" "$HOME/bin/asb"
```

Ensure `$HOME/bin` is on your `PATH` (for example by adding it to `~/.bashrc`).

## Usage

Launch a sandbox by short name:

```sh
asb 0
```

This resolves to `agent-sandbox-0` and launches it via `termux-sandbox`.

You can print paths for scripting:

```sh
asb 0 --workdir-path
asb 0 --rootfs-path
```

On first run, the rootfs is bootstrapped from the Termux app bootstrap (a clean
base install).

You can also invoke the launcher directly:

```sh
termux-sandbox agent-sandbox-test
```

### Options

```sh
termux-sandbox <name> [options]
```

Options:

- `--bootstrap[=MODE]`: Bootstrap mode: `termux` (default), `prefix`, `mirror`, `url`, `file`.
- `--bootstrap-url URL`: Download bootstrap zip from URL (implies `url` mode).
- `--bootstrap-file PATH`: Use an existing bootstrap zip file (implies `file` mode).
- `--no-bootstrap`: Do not bootstrap; error if the rootfs is missing `bin/bash`.
- `--rootfs DIR`: Override the rootfs location.
- `--workdir DIR`: Override the workdir location.

`asb` passes any additional options through to `termux-sandbox`.

## Layout

- Rootfs: `$HOME/sandboxes/agent-sandbox-<name>`
- Workdir: `$HOME/agent-work-<name>`
