# Code Review Focus: Bug Detection First

## Primary Objective
Focus exclusively on identifying real, actionable bugs. Prioritize in this order:
1. **Logic errors** — incorrect control flow, wrong conditionals, mishandled edge cases, off-by-one errors in loops
2. **Security vulnerabilities** — unvalidated inputs, unsafe `eval`, secrets hardcoded in scripts, unsafe path handling
3. **Data integrity issues** — race conditions in sourced files, missing guards on destructive operations, unhandled errors from external commands
4. **Performance regressions** — unconditional heavy operations at shell startup, blocking calls in the interactive path, redundant subshell forks

## What to SKIP
Do NOT comment on:
- Formatting or whitespace (handled by `shfmt`)
- Comment quality or documentation style
- Variable naming preferences unless they cause ambiguity bugs
- Warnings already flagged by `shellcheck` or CI linting
- Style/convention nits — local linting enforces these

## Comment Style
- Be direct and concise. State the bug, explain why it's a problem, suggest the fix.
- Every comment must include a concrete reproduction scenario or explain the exact failure condition.
- No suggestions that are purely aesthetic.
- If you are not confident a finding is a real bug, do not comment.

## Codebase-Specific Rules

### Shell scripting (`.zsh`, `.sh`, `*.zsh.tmpl`, `*.sh.tmpl`)
- **Unquoted variables**: Unquoted `$VAR` in word-splitting contexts is a bug — paths with spaces or glob characters will break. Flag `$VAR` that should be `"$VAR"`.
- **`[ ]` vs `[[ ]]`**: ZSH files should use `[[ ]]`. Bare `[ ]` lacks ZSH-specific features and can misfire on empty strings or special characters. Flag `[ ]` usage in `.zsh` files.
- **Command substitution**: `$(cmd)` is correct; backtick substitution `` `cmd` `` is error-prone in nested contexts. Flag backtick substitution.
- **`source` vs `.`**: Both work in ZSH, but mixing them inconsistently in the same file is a maintenance footgun. Flag only if it causes a real incompatibility.
- **Exit code loss**: Piping through another command swallows exit codes (`cmd | tee file` loses cmd's exit). Flag in scripts that rely on `$?` after a pipeline.

### Chezmoi templates (`.tmpl` files)
- **Unclosed `{{ }}` blocks**: An unmatched `{{` or missing `{{ end }}` will silently produce broken output. Flag any template block that appears to be missing its closing tag.
- **Wrong OS comparisons**: The correct check is `{{ if eq .chezmoi.os "darwin" }}` or `"linux"`. Flag typos like `"macos"`, `"mac"`, `"osx"`, or `"Ubuntu"` — they evaluate to false silently.
- **Whitespace-sensitive values**: Template output inserted into PATH or sourced file paths must use `{{- trim -}}` or equivalent when surrounding whitespace would break the value. Flag unguarded template expressions inside PATH assignments or `source` paths.
- **Missing variable guards**: Accessing a custom chezmoi data key (`.chezmoi.data.foo`) without a `hasKey` check will panic at render time. Flag direct access to non-standard data keys.

### Sheldon plugin config (`plugins.toml.tmpl`, `plugins.toml`)
- **Invalid TOML**: A syntax error in the plugin config silently disables all plugins. Flag malformed table headers, unclosed strings, or duplicate keys.
- **Broken `use` references**: A `use = ["file.zsh"]` that references a nonexistent file in the plugin repo causes a silent load failure. Flag `use` values that don't match typical entrypoint names unless there is clear evidence the file exists.
- **Malformed `inline_hook`**: An `inline_hook` block that calls a function before it's defined, or that contains unbalanced braces, will break ZSH startup. Flag inline hooks that reference symbols not yet in scope.

### PATH and environment variable management
- **Unconditional duplicate PATH entries**: `export PATH="$HOME/bin:$PATH"` added without a guard (e.g., `[[ ":$PATH:" != *":$HOME/bin:"* ]]`) will inflate PATH on every shell re-source. Flag entries lacking a deduplication guard.
- **Unguarded tool exports**: `export FOO=$(tool-cmd)` where `tool-cmd` may not be installed will produce an empty or error-containing variable. Flag exports that invoke external tools without an existence check (`command -v tool-cmd`).
- **Mise/asdf mutual exclusion**: This repo enforces strict mutual exclusion between `asdf` and `mise`. Flag any code that activates both in the same shell session or removes the mutual-exclusion guard.

### PEP 723 / standalone Python scripts (`scripts/`, `hack/`)
- Standalone scripts intended to be run via `uv run` must have the `#!/usr/bin/env -S uv run` shebang and a `# /// script` inline metadata block. Flag scripts missing this block — they will fail when invoked directly.
