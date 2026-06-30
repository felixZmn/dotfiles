# install.sh — specification

Idempotent dotfiles installer for Unix-like systems (bash). Creates symlinks from the repo into the home directory and injects a bootstrap block into `~/.bashrc`.

**Implementation:** `install.sh`  
**Helpers:** `lib/helpers.sh`  
**PowerShell counterpart:** `install.ps1`, `lib/helpers.ps1`

---

## Platform differences

The bash and PowerShell installers serve the same purpose but differ in important platform-specific ways. Differences are not deviations — they are intentional:

| Aspect | Bash (Unix) | PowerShell (Windows) |
| ------ | ----------- | -------------------- |
| Link type | Symlinks (`ln -sfn`) | Hardlinks (`New-Item -ItemType HardLink`) |
| Git deployment | Fully deployed (`git/.gitconfig`, `git/.gitignore_global`, `git/hooks/`) | Not deployed — Windows Git paths differ; handled separately by the user |
| k9s | Deployed (`config.yaml`, `skin.yaml`) | Not deployed — k9s is Unix-specific |
| PowerShell scripts | N/A | Deployed to `$HOME\.dotfiles\powershell\` |
| Profile injection | `inject_bashrc` — appends marker block sourcing `~/.bash_aliases` | `InjectProfile` — appends marker block sourcing aliases to all applicable PowerShell profiles |

---

## Purpose

Deploy tracked config files and scripts so a fresh clone matches the author’s environment without overwriting unrelated shell customization.

---

## Execution model

```bash
#!/usr/bin/env bash
set -euo pipefail
```

- Resolves `DOTFILES_DIR` to the directory containing `install.sh`
- Sources `lib/helpers.sh` (which sets its own `DOTFILES_DIR` relative to `lib/`)
- Runs sections sequentially; any helper failure aborts the install (`set -e`)

---

## Deploy map

Each step prints a section header, then calls `link <repo-relative-src> <dest>`.

| Section | Source (repo) | Destination (home) |
| ------- | ------------- | ------------------- |
| Git | `git/.gitconfig` | `~/.gitconfig` |
| Git | `git/.gitignore_global` | `~/.gitignore_global` |
| Git hooks | `git/hooks/` (directory) | `~/.config/git/hooks` |
| Vim | `vim/.vimrc` | `~/.vimrc` |
| Bash scripts | `bash/scripts/` (directory) | `~/.local/bin/dotscripts` |
| Bash aliases | `bash/aliases` | `~/.bash_aliases` |
| k9s | `k9s/config.yaml` | `~/.config/k9s/config.yaml` |
| k9s | `k9s/skin.yaml` | `~/.config/k9s/skins/skin.yaml` |

After links: `inject_bashrc`, then success message.

---

## Helper: `link`

**Signature:** `link <src-relative-to-DOTFILES_DIR> <absolute-dest>`

**Behavior:**

1. Resolve `src="$DOTFILES_DIR/$1"`.
2. `mkdir -p "$(dirname "$dest")"`.
3. If `dest` exists and is **not** a symlink: move to `dest.bak` (one-time backup).
4. `ln -sfn "$src" "$dest"` — symlink, force replace.
5. Print `Linked $dest`.

**Notes:**

- Existing symlinks are replaced without backup.
- Regular files at destination are backed up, not deleted.

---

## Helper: `inject_bashrc`

**Target:** `$HOME/.bashrc`  
**Marker:** `# >>> dotfiles >>>`

**Behavior:**

1. If marker not found in `.bashrc`, append block:

   ```bash
   # >>> dotfiles >>>
   [ -f "$HOME/.bash_aliases" ] && source "$HOME/.bash_aliases"
   # <<< dotfiles <<<
   ```

2. If marker present: skip (idempotent).
3. Print whether updated or skipped.

**Effect:** `~/.bash_aliases` sources all `~/.local/bin/dotscripts/*.sh` (including `prompt.sh`, `kuse.sh`).

---

## Post-install

Print:

```
✅ Done! Restart your shell or run: source ~/.bashrc
```

---

## Idempotency

| Operation | Re-run behavior |
| --------- | --------------- |
| `link` | Refreshes symlinks; backs up only non-symlink collisions |
| `inject_bashrc` | Skips if marker exists |

Safe to run multiple times.

---

## Platform comparison (install.ps1)

| Concern | install.sh | install.ps1 |
| ------- | ---------- | ----------- |
| Link type | Symlink (`ln -sfn`) | Hard link (`New-Item -ItemType HardLink`) |
| Git / hooks | Deployed | Currently commented out |
| Shell scripts | Whole `bash/scripts` dir → dotscripts | Individual files under `~/.dotfiles/powershell/scripts` |
| Aliases | `~/.bash_aliases` | `~/.dotfiles/powershell/aliases.ps1` |
| Bootstrap | `inject_bashrc` → `.bashrc` | `InjectProfile` → `$PROFILE` paths |
| k9s / vim | Linked | Vim only (k9s not in PS installer) |
| Error mode | `set -euo pipefail` | `$ErrorActionPreference = "Stop"` |

---

## Dependencies

- bash
- `ln`, `mkdir`, `mv`, `grep`
- Write access to `$HOME` and config paths under it

---

## Out of scope (current implementation)

- CLI flags (`--force`, `--bash`, etc.) mentioned in README are not implemented in `install.sh`
- No secret / credential prompting
- No uninstall or dry-run mode
