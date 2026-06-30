# kuse.sh — specification

Kubernetes config switcher for bash/zsh. Source from shell config or via dotfiles `bash/aliases` auto-loading.

**Implementation:** `bash/scripts/kuse.sh`  
**PowerShell counterpart:** `powershell/scripts/kuse.ps1`

---

## Purpose

Safely switch between multiple kubeconfig files stored in a dedicated directory by setting `KUBECONFIG`. Avoids overwriting the default `~/.kube/config`.

---

## Configuration

| Variable | Default | Description |
| -------- | ------- | ----------- |
| `KUBE_CONFIGS_DIR` | `$HOME/.kube/configs` | Directory containing kubeconfig files |
| `KUBECONFIG` | (unset or user-set) | Active config path; set by `kuse <name>` and `kuse --reset` |

Config directory is resolved once at source time via `_kube_resolve_dir`.

---

## CLI

| Invocation | Behavior |
| ---------- | -------- |
| `kuse` | List configs; print tip footer |
| `kuse <name>` | Activate named config |
| `kuse -l`, `kuse --list` | List configs only (no tip) |
| `kuse -c`, `kuse --current` | Show active file, context, and full context table |
| `kuse -r`, `kuse --reset` | Set `KUBECONFIG` to `$HOME/.kube/config` |
| `kuse -h`, `kuse --help` | Show usage |
| `kuse -<unknown>` | Error message; exit code 1 |

`<name>` is resolved against `$KUBE_CONFIGS_DIR/<name>`, then `<name>.yaml`, then `<name>.yml`. First existing file wins.

---

## Subcommand behavior

### List (`_kuse_list`)

1. Verify config dir exists; fail with mkdir hint if missing.
2. Print header and directory path.
3. If no regular files in dir: warn and suggest copying configs.
4. For each file: mark active entry with `▶` (green) and `← active` when `$KUBECONFIG` equals full path; others use `◦` (blue).

### Switch (`_kuse_switch`)

1. Verify config dir exists.
2. Resolve `<name>` to a file; on failure print not-found and list hint.
3. `export KUBECONFIG=<resolved path>`.
4. Print success with basename, current context (`kubectl config current-context`), and comma-separated list of all context names.

### Current (`_kuse_current`)

1. Print active file: `${KUBECONFIG:-$HOME/.kube/config}`.
2. If `kubectl config current-context` fails or is empty: show `(unavailable)` in red.
3. Otherwise print context and run `kubectl config get-contexts`.

### Reset (`_kuse_reset`)

1. `export KUBECONFIG=$HOME/.kube/config`.
2. Print reset message.
3. If default file missing: warn only (no error exit).
4. If present and context available: print current context.

---

## Shared helpers

| Helper | Role |
| ------ | ---- |
| `_kube_test_dir` | Ensure `$_KUBE_CONFIGS_DIR` exists |
| `_kube_find_config` | Set `_KUBE_FOUND_PATH` from name + extension candidates |
| `_kube_current_context` | Set `_KUBE_CTX` via kubectl; default `(none)` |
| `_kube_all_contexts` | Set `_KUBE_ALL_CTX` as comma-separated context names |

---

## Output and colors

Colors enabled only when stdout is a TTY (`[ -t 1 ]`). Otherwise all color variables are empty.

| Token | Color |
| ----- | ----- |
| Errors | Red |
| Success / active marker | Green |
| Tips / metadata | Cyan |
| Warnings | Yellow |
| Inactive list items | Blue |
| Headers | White + blue rule |

Print helpers: `_kube_print` (newline), `_kube_print_inline` (no newline), `_kube_header`.

---

## Dependencies

- `kubectl` — required for context queries in switch/current/reset
- POSIX `sh` shebang; bash/zsh extensions used only for tab completion blocks

---

## Tab completion

Registered when sourced in bash or zsh:

- **Flags:** `--list`, `--current`, `--reset`, `--help`, `-l`, `-c`, `-r`, `-h`
- **Names:** basenames of regular files in `$_KUBE_CONFIGS_DIR`

---

## Error handling

| Condition | Result |
| --------- | ------ |
| Config dir missing | Message + hint; return 1 (list/switch) |
| Unknown config name | Message + hint; return 1 |
| Unknown flag | Message + hint; return 1 |
| Missing default config on reset | Warning only; return 0 |
| Empty config directory | Informational; return 0 |

---

## Integration

- Sourced automatically when `bash/aliases` loads all `~/.local/bin/dotscripts/*.sh` (via `install.sh`).
- `kube_info` in `prompt.sh` reads the same `KUBECONFIG` / default path that `kuse` sets; it does not invoke `kuse` at prompt time.
