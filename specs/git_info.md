# git_info — prompt specification

Bash prompt segment showing Git branch and working-tree summary. Mirrors `Get-GitStatus` / git segment in `powershell/scripts/profile.ps1`.

**Implementation:** `git_info()` in `bash/scripts/prompt.sh`

---

## Purpose

When the current directory is inside a Git repository, append a compact, color-coded status block to `PS1`. When not in a repo (or `git status` fails), produce no output.

---

## Data source

```bash
git status --porcelain=v2 --branch
```

- stderr discarded (`2>/dev/null`)
- If output is empty, function returns immediately with no prompt segment

---

## Parsing rules

Process line-by-line.

### Branch metadata (lines starting with `#`)

| Line pattern | Captured value |
| ------------ | -------------- |
| `# branch.head <name>` | `branch_name` |
| `# branch.ab +<ahead> -<behind>` | `ahead`, `behind` (integers) |

Other `#` lines are ignored.

### File status (non-`#` lines)

Use first character (`char`) and XY positions for v1/v2 entries:

| Condition | Effect |
| --------- | ------ |
| `char == ?` | `untracked++` |
| `char == u` | `modified++` (unmerged/conflict) |
| `char == 1` or `char == 2` | If index column (`line[2]`) ≠ `.` → `staged++`; if worktree column (`line[3]`) ≠ `.` → `modified++` |

Note: PowerShell `Get-GitStatus` also parses `# branch.oid` and `# branch.upstream`; bash `git_info` does not surface hash or upstream in the prompt.

---

## Output format

Segments are concatenated in order. Non-printing escape wrappers `\[` `\]` wrap ANSI codes for correct line-length calculation in bash.

| Segment | Condition | Format | ANSI (bold unless noted) |
| ------- | --------- | ------ | ------------------------ |
| Branch open | always (when in repo) | ` [${branch_name}` | Yellow `1;33` |
| Ahead | `ahead > 0` | ` ↑${ahead}` | Green `1;32` |
| Behind | `behind > 0` | ` ↓${behind}` | Red `1;31` |
| Branch close | always | `]` | Yellow `1;33` |
| Staged | `staged > 0` | ` +${staged}` | Green `1;32` |
| Modified | `modified > 0` | ` ~${modified}` | Red `1;31` |
| Untracked | `untracked > 0` | ` ?${untracked}` | Magenta `35` (not bold) |
| Reset | always | `\033[0m` | — |

Example (conceptual): ` [main ↑2 ↓1]+1 ~3 ?2`

No trailing space after the reset sequence; caller (`PS1`) supplies spacing before `$`.

---

## PS1 integration

Full prompt layout in `prompt.sh`:

```
$userHost:$path$(kube_info)$(git_info) \$
```

- `userHost`: bold green `\u@\h`
- `path`: bold blue `\w`
- `git_info` runs as command substitution on each prompt render

---

## Behavior summary

| Scenario | Output |
| -------- | ------ |
| Not a git repo / git unavailable | (empty) |
| Clean repo on branch `main` | ` [main]` |
| Detached HEAD | Branch name from porcelain (may be commit hash) |
| No upstream / no ab line | Ahead/behind omitted (0) |

---

## Dependencies

- `git` on `PATH`
- Bash (arrays, `BASH_REMATCH`, `<<<`, arithmetic)

---

## Cross-platform parity

PowerShell prompt uses the same porcelain=v2 parsing and color scheme for branch, ahead/behind, staged, modified, and untracked. Differences:

- PowerShell shows path as `PS <cwd>`; bash shows `user@host:path`
- PowerShell omits segment entirely when `Get-GitStatus` returns `$null`; bash omits when porcelain output is empty
