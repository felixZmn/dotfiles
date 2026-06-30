# kube_info — prompt specification

Bash prompt segment showing the active Kubernetes context. Mirrors `Get-KubeContext` in `powershell/scripts/profile.ps1`.

**Implementation:** `kube_info()` in `bash/scripts/prompt.sh`

---

## Purpose

When a kubeconfig file exists and declares a `current-context`, append a compact context label to `PS1`. When unavailable, produce no output (silent no-op).

---

## Kubeconfig resolution

Same logic as `kuse.sh` / `kuse.ps1`:

```bash
kubeconfig_path="${KUBECONFIG:-$HOME/.kube/config}"
```

1. Honor `KUBECONFIG` if set (including values set by `kuse <name>`).
2. Otherwise use `$HOME/.kube/config`.

If the resolved path is not a regular file, return immediately with no output.

---

## Context extraction

Read file directly — **no `kubectl` subprocess**:

```bash
grep -m1 "^current-context:" "$kubeconfig_path" \
  | sed 's/^current-context:[[:space:]]*//'
```

- First matching `current-context:` line wins
- Leading whitespace after colon stripped
- If result is empty, return with no output

Rationale (also documented in PowerShell): file read ~1 ms vs ~200 ms for spawning `kubectl`.

---

## Output format

| Element | Value |
| ------- | ----- |
| Prefix | Space + `[` |
| Icon | `☸` (Kubernetes wheel) |
| Body | Space + context name |
| Suffix | `]` |
| Style | Bold cyan ANSI `1;36` |
| Reset | `\033[0m` |

Non-printing bytes `\001` / `\002` wrap ANSI sequences so bash counts prompt width correctly.

Example: ` [☸ minikube]` (bold cyan)

---

## PS1 integration

```
$userHost:$path$(kube_info)$(git_info) \$
```

`kube_info` appears **before** `git_info`, matching PowerShell prompt order (path → kube → git).

---

## Behavior summary

| Scenario | Output |
| -------- | ------ |
| No kubeconfig file | (empty) |
| File exists, no `current-context` line | (empty) |
| `current-context:` with empty value | (empty) |
| Valid context `prod-eu` | ` [☸ prod-eu]` (styled) |

---

## Relationship to kuse

| Action | Effect on prompt |
| ------ | ---------------- |
| `kuse my-cluster` | Sets `KUBECONFIG`; prompt reads that file’s `current-context` |
| `kuse --reset` | Points to `~/.kube/config` |
| Unset `KUBECONFIG` | Falls back to default path |

`kube_info` does not call `kuse`; it only reads the same env var and file path conventions.

---

## Dependencies

- `grep`, `sed`
- Readable kubeconfig file (YAML text; no schema validation)

---

## Cross-platform parity

`Get-KubeContext` in `profile.ps1` uses the same resolution order and `^current-context:` parsing via `Select-String`. Output styling matches: bold cyan `[☸ <ctx>]`.
