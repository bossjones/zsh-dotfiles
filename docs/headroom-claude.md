# hclaude: running Claude Code through headroom

A guide to the `hclaude`, `headroom_start`, `headroom_stop`, and `headroom_status`
functions added to `home/shell/customs/aliases.zsh`, which run
[Claude Code](https://claude.com/claude-code) through a local
[headroom](https://github.com/headroomlabs-ai/headroom) compression proxy.

headroom sits between Claude Code and Anthropic's API, compressing tool output,
logs, and file contents before they're sent — cutting token usage without changing
how you use Claude Code. It's opt-in: nothing here changes plain `claude` invocations,
these are separate wrapper functions you call instead.

## Prerequisites

- The [`headroom`](https://github.com/headroomlabs-ai/headroom) CLI installed and on
  `$PATH` (e.g. `uv tool install headroom`). Not installed by this repo's provisioning
  — install it yourself first.
- `claude` (Claude Code) on `$PATH`.

**Why proxy mode, not `headroom wrap claude`:** headroom's wrap mode installs an
internal component also named "rtk" ("Realtime Token Kompress"), which shadows the
real `rtk` (Rust Token Killer) binary this repo's Claude Code hooks rely on for
shrinking bash output. Running `headroom proxy` directly and
pointing Claude Code at it via `ANTHROPIC_BASE_URL` avoids that collision entirely.
See [the reference gist](https://gist.github.com/bossjones/70e6c4fa3aae857cbfe8761ade5d19c8)
for the full writeup.

## 1. Managing the proxy

### `headroom_start`

Starts `headroom proxy` in the background, writes its PID to
`/tmp/headroom-proxy.pid`, and redirects its output to `/tmp/headroom-proxy.log`.
Safe to call repeatedly — if a proxy is already running, it just reports that and
returns.

```bash
headroom_start
# [headroom_start] started headroom proxy on port 8787 (pid 12345, log /tmp/headroom-proxy.log)
```

### `headroom_status`

Reports whether the proxy is currently running, and on which port.

```bash
headroom_status
# [headroom_status] running (pid 12345, port 8787)
```

### `headroom_stop`

Kills the backgrounded proxy and removes the PID file. Safe to call when nothing is
running.

```bash
headroom_stop
# [headroom_stop] stopped
```

## 2. Running Claude Code through the proxy: `hclaude`

`hclaude` is a thin passthrough — it sets `ANTHROPIC_BASE_URL` to point at the local
proxy, then forwards every argument straight to `claude`. Any flag combination you'd
pass to `claude` works unchanged:

```bash
headroom_start
hclaude --model sonnet --permission-mode plan
hclaude --model opus --permission-mode plan --resume
hclaude --enable-auto-mode --model haiku --permission-mode plan
hclaude --model sonnet --permission-mode auto "$(cat some-prompt.md)"
```

If the proxy isn't running when you call `hclaude`, it prints a warning to stderr
and proceeds anyway (requests will simply fail to reach `localhost:$HEADROOM_PORT`
until you run `headroom_start`) — `hclaude` never blocks or manages the proxy for
you, by design, so it stays a predictable, thin wrapper.

## 3. Configuration

| Variable | Default | Purpose |
|----------|---------|---------|
| `HEADROOM_PORT` | `8787` | Port the proxy listens on and `hclaude` targets. Set once per shell (or in your own `env.zsh`/profile) to use a non-default port. |

```bash
HEADROOM_PORT=9000 headroom_start
HEADROOM_PORT=9000 hclaude --model sonnet
```

## 4. Troubleshooting

- **`hclaude` prints a warning about the proxy not running** — run `headroom_start`
  first, or check `headroom_status`.
- **Claude Code hangs or errors immediately** — check `/tmp/headroom-proxy.log` for
  startup errors (e.g. port already in use, `headroom` not on `$PATH`).
- **Stale PID file after a crash** — `headroom_status` and `headroom_stop` both check
  `kill -0` before trusting the PID file, so a dead process is detected and the file
  is cleaned up on the next `headroom_stop` call.
- **`rtk` (Rust Token Killer) output shrinking stops working** — you likely ran
  `headroom wrap claude` instead of using `hclaude`; see the "Why proxy mode" note
  above.

## 5. How it's wired

All four functions live in `home/shell/customs/aliases.zsh`, loaded like every other
personal alias/function in this repo (see [Architecture](architecture.md#4-module-convention-home-shelltoolenvpathcompletionkeybindingaliaseszsh)).
No chezmoi templating or feature flag is involved — they're always defined; whether
you use them is up to you.
