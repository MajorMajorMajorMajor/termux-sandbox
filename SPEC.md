# Termux Sandbox Interface Spec

## Tool overview
- **termux-sandbox**: a general-purpose CLI to create, run, and manage named Termux sandboxes.
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
termux-sandbox <command> [<name>] [command...] [options]
```

### Commands
- `run <name> [command...]`: Run a sandbox, optionally executing a command.
- `create <name>`: Bootstrap a sandbox without entering it.
- `rm <name>`: Remove the sandbox rootfs and workdir.
- `list`: List existing sandboxes.
- `info <name>`: Print rootfs and workdir paths for the sandbox.
- `help`: Show help.

### Default behavior
- If no command is provided and the first argument is a name, `run` is implied:
  ```
  termux-sandbox <name> [command...] [options]
  ```

### Options (shared)
- `--bootstrap[=MODE]`: Bootstrap mode: `termux` (default), `prefix`, `mirror`, `url`, `file`.
- `--bootstrap-url URL`: Download bootstrap zip from URL (implies `url` mode).
- `--bootstrap-file PATH`: Use an existing bootstrap zip file (implies `file` mode).
- `--no-bootstrap`: Do not bootstrap; error if rootfs missing `bin/bash`.
- `--rootfs DIR`: Override the rootfs location.
- `--workdir DIR`: Override the workdir location.

### Output conventions
- `list` prints one sandbox name per line.
- `info` prints:
  ```
  rootfs: <path>
  workdir: <path>
  ```

## asb (personal helper)

### Command structure
```
asb <command> [<name>] [command...] [options]
```

### Commands
- `run <name> [command...]`: Run a sandbox (default).
- `create <name>`: Bootstrap a sandbox.
- `rm <name>`: Remove sandbox rootfs and workdir.
- `list`: List existing sandboxes.
- `info <name>`: Print rootfs and workdir paths.
- `help`: Show help.

### Default behavior
- If no command is provided and the first argument is a name, `run` is implied:
  ```
  asb <name> [command...] [options]
  ```

### Naming
- `asb` expands short names to `agent-sandbox-<name>`.
- `asb` passes through any additional args to `termux-sandbox`.

### Optional convenience flags
- `--rootfs-path` and `--workdir-path` may be retained for scripting convenience.

## Future commands (planned)
- `copy <name> <new-name>`
- `snapshot <name>`
- `revert <name> [snapshot]`
- `reset <name>`
