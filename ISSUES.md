# Known Issues

## 1. Relay overwrites sandbox `am` permanently
**Severity: High** — Data loss / breaks sandbox on next run without relay

`termux-sandbox` copies the relay client over `$ROOTFS/bin/am` every launch.
This destroys the original `am` script in the rootfs. If the sandbox is later
run without the relay (different launcher, direct proot invocation, etc.),
`am` is permanently broken.

**Fix:** Use a PATH-based override instead of clobbering the file. For example,
create a `$ROOTFS/tmp/sandbox-bin/` directory containing the relay client as
`am`, and prepend it to `PATH` in the proot environment. This leaves the
original `am` untouched.

**Files:** `termux-sandbox` (relay setup block near line 368)

## 2. `eval` in relay server is fragile
**Severity: Medium** — Correctness risk with special characters in arguments

`sandbox-relay.sh` uses `eval "am $cmd_args"` where `$cmd_args` comes from the
client's shell-escaped arguments. While the client's quoting looks correct,
`eval` is inherently fragile. Arguments with unusual characters (backticks,
`$()`, newlines) could break or behave unexpectedly.

**Fix:** Have the client write arguments as null-delimited raw values (one per
line or null-separated), and have the server reconstruct the argument array
without `eval`. For example, write one arg per null byte and read with
`xargs -0` or a `while IFS= read -r -d ''` loop.

**Files:** `scripts/sandbox-relay.sh`, `scripts/sandbox-relay-client.sh`

## 3. Relay server hardcodes `am`
**Severity: Low** — Limits future extensibility

The relay server only executes `am` commands. This works for all current
callers (`termux-open-url`, `termux-notification`, etc.) because they all go
through `am`. But the architecture doesn't support relaying other commands
that might break under proot in the future.

**Fix:** Make the relay generic. The client sends the full command (e.g.,
`am start ...` or `app_process ...`) and the server executes whatever it
receives. The client would then be a general-purpose "run on host" proxy,
not just an `am` replacement.

**Files:** `scripts/sandbox-relay.sh`, `scripts/sandbox-relay-client.sh`

## 4. Relay client has no fallback
**Severity: Low** — Poor degradation when relay is not running

If the relay server isn't running, the client prints an error and exits.
There's no attempt to fall back to the original `am` (which would fail
silently under proot anyway, but at least the behavior would match what
the user saw before the relay existed).

**Fix:** If the relay directory doesn't exist, try the original `am`
(`app_process` path) as a fallback. It will probably fail, but the error
message would come from the original tool rather than from our relay
infrastructure.

**Files:** `scripts/sandbox-relay-client.sh`

## 5. Race condition in relay cleanup
**Severity: Low** — Could cause intermittent failures on slow devices

The relay server cleans up request directories with a background
`(sleep 1 && rm -rf "$req_dir") &`. The client reads the exit code file
after the response FIFO. On a slow device, the 1-second cleanup could
race with the client reading the exit code.

**Fix:** Let the client own cleanup of its own request directory (it
already does `rm -rf "$req_dir"` at the end). Remove the server-side
background cleanup entirely.

**Files:** `scripts/sandbox-relay.sh`, `scripts/sandbox-relay-client.sh`

## 6. `cleanup_relay` called twice in termux-sandbox
**Severity: Trivial** — No functional impact, just noise

The EXIT trap calls `cleanup_relay`, and there's also an explicit
`cleanup_relay` call after the `proot` command. Both fire on normal exit.

**Fix:** Remove the explicit `cleanup_relay` call after proot. The EXIT
trap handles it.

**Files:** `termux-sandbox`

## 7. `SCRIPT_DIR` computed late in `asb`
**Severity: Trivial** — Fragile if script grows

`SCRIPT_DIR` is only computed at the bottom of `asb`, right before exec.
If the script grows or is sourced, this is easy to miss.

**Fix:** Move `SCRIPT_DIR` computation to the top of the script, after
the argument check.

**Files:** `asb`
