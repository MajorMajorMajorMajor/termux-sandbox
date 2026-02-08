# Termux Sandbox Interface Spec

## Tool overview
- **termux-sandbox**: a general-purpose CLI to create (bootstrap if needed) and run a named Termux sandbox.
- **asb**: a personal helper that shortens common sandbox workflows and applies a consistent name prefix.

## Goals
- Provide a clear, explicit CLI for general Termux users.
- Keep `termux-sandbox` stable and predictable.
- Provide a streamlined, ergonomic wrapper (`asb`) for personal use.
- Keep both tools consistent in naming and behavior.

## Glossary
- **sandbox**: a named rootfs + workdir pair.
- **rootfs**: the isolated filesystem used by the sandbox.
- **workdir**: the bind-mounted workspace directory.

## termux-sandbox (public tool)

### Command structure
```
termux-sandbox <name> [options]
```

`<name>` is required.

### Current behavior
- Requires `proot`.
- Uses default paths unless overridden:
  - Rootfs: `$HOME/sandboxes/<name>`
  - Workdir: `$HOME/agent-work-<short-name>` where `<short-name>` is `<name>`
    without the `agent-sandbox-` prefix (if present).
- If rootfs is missing `bin/bash`, bootstraps according to selected mode.
- Applies Termux symlinks after bootstrap.
- Launches an interactive shell in the sandbox.

### Options
- `--bootstrap[=MODE]`: Bootstrap mode: `termux` (default), `prefix`, `mirror`, `url`, `file`.
- `--bootstrap-url URL`: Download bootstrap zip from URL (implies `url` mode).
- `--bootstrap-file PATH`: Use an existing bootstrap zip file (implies `file` mode).
- `--no-bootstrap`: Do not bootstrap; error if rootfs missing `bin/bash`.
- `--rootfs DIR`: Override the rootfs location.
- `--workdir DIR`: Override the workdir location.
- `-h, --help`: Show help.

## asb (personal helper)

### Command structure
```
asb <name> [termux-sandbox options]
```

`<name>` is required.

### Current behavior
- Expands short names to `agent-sandbox-<name>` unless already prefixed.
- Resolves paths:
  - Rootfs: `$HOME/sandboxes/<sandbox-name>`
  - Workdir: `$HOME/agent-work-<short-name>`
- Supports convenience flags:
  - `--rootfs-path`: print resolved rootfs path and exit.
  - `--workdir-path`: print resolved workdir path and exit.
- If sandbox is missing:
  - interactive mode prompts to create;
  - non-interactive mode exits with error.
- Delegates execution to `termux-sandbox`.

## Out of scope (not implemented)
The following command-oriented interface is not currently implemented and is out
of scope for the current release:

- `run <name> [command...]`
- `create <name>`
- `rm <name>`
- `list`
- `info <name>`
- `copy <name> <new-name>`
- `snapshot <name>`
- `revert <name> [snapshot]`
- `reset <name>`
