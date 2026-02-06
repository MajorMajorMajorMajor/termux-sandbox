# asb

A personal helper that expands short sandbox names and delegates to
`termux-sandbox`.

## Usage
```sh
asb <name> [termux-sandbox options]
```

`<name>` is required. If it does not start with `agent-sandbox-`, the prefix is
added automatically.

## Behavior
- Resolves paths based on the expanded sandbox name:
  - Rootfs: `$HOME/sandboxes/<sandbox-name>`
  - Workdir: `$HOME/agent-work-<short-name>` where `<short-name>` is the expanded
    name without the `agent-sandbox-` prefix.
- If the rootfs is missing `bin/bash`:
  - In interactive mode, prompts to create the sandbox.
  - In non-interactive mode, exits with an error.
- Delegates to `termux-sandbox` if available on `PATH`; otherwise runs the
  co-located `termux-sandbox` script.

## Flags
- `--rootfs-path`: Print the rootfs path and exit.
- `--workdir-path`: Print the workdir path and exit.
- `-h, --help`: Show help (passed through to `termux-sandbox` when a name is
  provided).

## Examples
```sh
asb 0
asb agent-sandbox-dev
asb 0 --rootfs-path
asb 0 --workdir-path
asb 0 --bootstrap=mirror
```
