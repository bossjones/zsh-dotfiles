# mise Configuration (`mise.toml`)

Deep-dive on the file format. For an introduction to mise itself see [mise_overview.md](./mise_overview.md). For repo-specific migration see [asdf-to-mise-migration.md](../workflows/asdf-to-mise-migration.md).

The full spec lives at <https://mise.jdx.dev/configuration.html> — **WebFetch it** when you need an obscure section (`[plugins]`, `[tool_alias]`, `[shell_alias]`, `[hooks]`) or to verify exact merge semantics. This file covers what you'll reach for 90% of the time.

## File precedence

mise walks **upward from `cwd` to `/`** (or to `MISE_CEILING_PATHS`) collecting every config file along the way, then merges them — most-specific wins. Within a single directory the order is (highest → lowest precedence):

1. `mise.local.toml` — personal, git-ignored
2. `mise.toml` — project, committed
3. `mise/config.toml`
4. `.mise/config.toml`
5. `.config/mise.toml`
6. `.config/mise/config.toml`
7. `.config/mise/conf.d/*.toml` — alphabetical

Plus:

- **Global:** `~/.config/mise/config.toml`
- **System:** `/etc/mise/config.toml`
- **Environment-specific:** `mise.<env>.toml` (e.g. `mise.production.toml`), activated by `MISE_ENV=production`.

When `mise use` writes to disk it picks **the lowest-precedence file in the highest-precedence directory** — i.e. it edits the shared `mise.toml`, not your `mise.local.toml`. Run `mise config ls` to see exactly what's loaded.

## `[tools]`

Pin tool versions. `mise use <tool>@<ver>` adds entries here.

```toml
[tools]
node    = "24"           # loose: any 24.x (preferred for shared config)
python  = "3.12.4"       # exact: pin at the patch
ruby    = ["3.3", "3.2"] # multiple versions installed; first wins on PATH
go      = "latest"
kubectl = "1.30"

# Backend prefixes — install outside the default registry
ripgrep    = "ubi:BurntSushi/ripgrep"
fd         = "cargo:fd-find"
prettier   = "npm:prettier@3"
gh         = "aqua:cli/cli"
```

**Loose vs exact:** team configs should prefer loose (`"24"`) so collaborators aren't pinned to a stale patch. Use exact only when reproducibility matters (CI, locked deploy artifacts). For full reproducibility use a lockfile + `locked = true`.

**Backends** (`core`, `aqua`, `ubi`, `npm:`, `cargo:`, `pipx:`, `go:`, `asdf:`, `vfox:`) — see <https://mise.jdx.dev/dev-tools/backends/>. **WebFetch when** you can't find a tool in the default registry or you need to control where it comes from.

**Merging:** `[tools]` merges additively across the precedence chain. Global `node = "24"` plus project `python = "3.12"` gives you both, with project overriding only on conflicts.

## `[env]`

Set/clear env vars on directory entry.

```toml
[env]
NODE_ENV  = "development"
LOG_LEVEL = "debug"

# Special directives (underscore-prefixed)
_.path = ["./node_modules/.bin", "./bin"]   # prepend to PATH
_.python.venv = { path = ".venv", create = true }   # auto-activate / create venv
_.file = ".env"                              # load dotenv-style file
```

`[env]` merges additively — project values override global. `_.path` entries from inner configs come **before** outer ones, so the closest dir wins.

For secrets (`sops`, `age`, `1password`, `dotenv-vault`, AWS Secrets Manager, etc.) and templating syntax: <https://mise.jdx.dev/environments/>. **WebFetch when** doing anything beyond plain env-var assignments.

## `[tasks]`

Tasks are scripts mise runs in the activated environment. `mise run <name>`. Unlike `[tools]` and `[env]`, **tasks fully replace** across the precedence chain — a project task with the same name does not merge with a global one.

```toml
[tasks.lint]
run = "ruff check ."

[tasks.test]
run     = "pytest"
depends = ["lint"]

[tasks.ci]
depends = ["lint", "test"]

[tasks.serve]
run = "python -m http.server 8000"
dir = "{{ config_root }}/site"
```

Larger or more complex tasks belong in **`mise-tasks/`** — drop an executable file there and `mise run <filename>` finds it. mise reads `# usage:` comment headers for arg-parsing and shell-completion via the `usage` library.

Full task reference (args, env-per-task, `outputs`/`sources` for caching, file-based tasks, hooks): <https://mise.jdx.dev/tasks/>. **WebFetch when** authoring tasks with arguments, caching, or non-trivial dependency graphs.

## `[settings]`

Tunes mise's own behavior. Top settings worth knowing inline:

| Setting | Default | Use |
|---|---|---|
| `auto_install` | `true` | Install missing tools when needed (during `mise x`, `run`, etc.). |
| `not_found_auto_install` | `true` | If a binary isn't found, search registry and install. |
| `task_run_auto_install` | `true` | `mise run` triggers installs for missing tools. |
| `idiomatic_version_file_enable_tools` | `[]` | Opt-in list to read `.python-version`, `.nvmrc`, `.ruby-version`, `package.json` `engines`, etc. |
| `trusted_config_paths` | `[]` | Auto-trust `mise.toml` under these roots (skip `mise trust` prompts). |
| `experimental` | `false` | Gate for unstable features. |
| `paranoid` | `false` | Strict provenance checks. |
| `github_attestations` | `true` | Verify GitHub artifact attestations on download. |
| `slsa` | `true` | Verify SLSA provenance. |
| `locked` | `false` | Require pre-resolved URLs in a lockfile (CI hardening). |
| `jobs` | `8` | Parallelism for installs. |

`[settings.status]` controls what mise prints on directory entry:

| Sub-key | Default | Use |
|---|---|---|
| `show_tools` | `false` | Print tool versions when entering a configured dir. |
| `show_env` | `false` | Print env-var changes too. |
| `truncate` | `true` | Trim long lines. |
| `missing_tools` | `if_other_versions_installed` | Warn about uninstalled tools. Other values: `always`, `never`. |

Full ~80-setting catalog: <https://mise.jdx.dev/configuration/settings.html>. **WebFetch when** looking up a setting not in the table above (especially security/`paranoid`, lockfile, plugin-trust details).

## Real-world example

Adapted from [basher83/lunar-claude/mise.toml](https://github.com/basher83/lunar-claude/blob/main/mise.toml) — a sane, minimal Python-flavored config:

```toml
[settings]
auto_install            = true
not_found_auto_install  = true
task_run_auto_install   = true

[settings.status]
show_tools = true
show_env   = false
truncate   = true

[tools]
python      = "latest"
uv          = "latest"
ruff        = "latest"
shellcheck  = "latest"
ripgrep     = "ubi:BurntSushi/ripgrep"
fd          = "ubi:sharkdp/fd"

[env]
_.python.venv = { path = ".venv", create = true }

[tasks.lint]
run = ["ruff check .", "shellcheck scripts/*.sh"]

[tasks.test]
run = "pytest -q"

[tasks.ci]
depends = ["lint", "test"]
```

## `mise.local.toml`

Personal overrides that should not be committed. Add `mise.local.toml` to `.gitignore`. Typical uses:

- Pin a different python version locally for testing.
- Set machine-specific env vars (paths to local secrets, IDE-specific knobs).
- Override `[settings.status]` per developer preference.

`mise use` will not touch `mise.local.toml` by default — it goes to the shared `mise.toml`. Edit `mise.local.toml` by hand or with `mise use --local`.

## More

- Full configuration reference: <https://mise.jdx.dev/configuration.html>
- Settings: <https://mise.jdx.dev/configuration/settings.html>
- Tasks: <https://mise.jdx.dev/tasks/>
- Environments / secrets: <https://mise.jdx.dev/environments/>
