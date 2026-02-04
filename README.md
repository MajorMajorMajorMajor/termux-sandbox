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

You can also invoke the launcher directly:

```sh
termux-sandbox agent-sandbox-test
```

## Layout

- Rootfs: `$HOME/sandboxes/agent-sandbox-<name>`
- Workdir: `$HOME/agent-work-<name>`
