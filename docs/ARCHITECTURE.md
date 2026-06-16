# Architecture - Felix's Dotfiles Project Structure

## Overview

This repository uses a modular structure organized by **tool/service** rather than by operating system. This approach makes it easy to:

- Add new tools without refactoring existing code
- Find all configuration for a tool in one place
- Share configurations across platforms (where applicable)
- Understand dependencies between tools

## Directory Structure

```
dotfiles/
├── shells/                 # Shell environment configurations
│   ├── bash/
│   │   └── .bashrc        # Bash shell initialization
│   ├── zsh/
│   │   └── .zshrc         # Zsh shell initialization
│   └── powershell/
│       └── profile.ps1    # PowerShell profile
│
├── git/                   # Git version control configurations
│   ├── .gitconfig         # Git global config (signing, tools, aliases)
│   └── hooks/
│       └── commit-msg     # Git commit message validator
│
├── vim/                   # Text editor configurations
│   └── .vimrc             # Vim configuration (settings, mappings, plugins)
│
├── tools/                 # Third-party tool configurations
│   └── k9s/
│       └── skin.yaml      # Kubernetes TUI color theme
│
├── scripts/               # Installation and utility scripts
│   ├── install.sh         # Main installer for Linux/macOS
│   ├── install.ps1        # Main installer for Windows
│   └── detect-env.sh      # Environment detection helper
│
├── docs/                  # Project documentation
│   ├── ARCHITECTURE.md    # This file
│   ├── GIT_CONFIG.md      # Git configuration details
│   └── SHELL_CONFIG.md    # Shell prompt design details
│
├── .gitignore             # Git exclusion patterns
├── README.md              # Project overview and quick start
├── CONTRIBUTING.md        # Contribution guidelines
└── LICENSE                # MIT License
```

## Design Decisions

### 1. Tool-Based Organization (Not OS-Based)

**Why:** Users care more about configuring Git, Bash, and Vim than about organizing by OS.

**Example:**

```
✓ GOOD:  tools/k9s/skin.yaml
✗ BAD:   linux/k9s/skin.yaml, macos/k9s/skin.yaml, windows/k9s/skin.yaml
```

### 2. Shells Grouped Under `shells/`

**Why:** Multiple shell variants (bash, zsh, powershell) need coexistence and easy switching.

**Rationale:** Users often run multiple shells across machines; installer detects current shell and symlinks appropriately.

### 3. Git Hooks in `git/hooks/`

**Why:** Hooks are executable scripts, not text config. Grouping with .gitconfig shows ownership.

**Implementation:** Uses `git config --global core.hooksPath` instead of `.git/hooks/` — portable and doesn't require repository setup.

### 4. Single `.gitconfig` at `git/.gitconfig`

**Why:** Git only reads one global config file. Centralizing it in dotfiles makes it version-controlled and symmetric with shell configs.

**Symlink:** `git/.gitconfig` → `~/.gitconfig`

### 5. Scripts as Separate Installation Tools

**Why:**

- Installation logic is complex (multiple OSes, shells, edge cases)
- Scripts shouldn't be symlinked (they run at install time)
- One-time setup vs. persistent configuration separation

**Tools:**

- `install.sh` — Auto-detects OS/shell, creates symlinks, validates prerequisites
- `install.ps1` — Windows-specific PowerShell installation
- `detect-env.sh` — Helper for OS/shell/package manager detection (future use)

### 6. Documentation in `docs/` Folder

**Why:** Keeps README light and focused on quick start; detailed docs in separate files.

**Sections:**

- **ARCHITECTURE.md** — You are here (structure, rationale, design decisions)
- **GIT_CONFIG.md** — Detailed Git setup (signing, merging, aliases)
- **SHELL_CONFIG.md** — Prompt design, colors, customization

## Installation Flow

```
User runs:
  ./scripts/install.sh

Install script:
  1. Detects OS (Linux/macOS/Windows)
  2. Detects shell (bash/zsh/PowerShell)
  3. For each config file:
     a. Backup existing at ~/.config (if exists)
     b. Create symlink: ~/.config → dotfiles/config/path
  4. Configure git hooks: core.hooksPath = dotfiles/git/hooks/
  5. Validates prerequisites (git, vim, k9s, etc.)
  6. Prompts for secrets (email, SSH key) if --ask-secrets
  7. Shows summary and next steps
```

## Extensibility Model

### Adding a New Tool

1. **Create folder:**

   ```bash
   mkdir -p tools/tmux
   ```

2. **Add config files:**

   ```
   tools/tmux/
   ├── tmux.conf
   └── plugins.conf  # (optional)
   ```

3. **Update installer (scripts/install.sh):**

   ```bash
   # Add to main() function:
   log_info "Installing tmux configuration..."
   if command -v tmux &> /dev/null; then
       symlink_file "$DOTFILES_DIR/tools/tmux/tmux.conf" "$HOME/.tmux.conf"
   fi
   ```

4. **Document:**
   - Update README.md structure section
   - Add section to ARCHITECTURE.md if complex
   - Comment config files explaining non-obvious settings

5. **Test:**
   - Run installer on target platforms
   - Verify tool reads new config
   - Check Git log shows config correctly

### Adding a New Shell

1. **Create folder:**

   ```bash
   mkdir -p shells/fish
   ```

2. **Add config:**

   ```
   shells/fish/
   └── config.fish
   ```

3. **Update installer:**

   ```bash
   # In detect_shell() function:
   case "$SHELL" in
       *fish) echo "fish" ;;
       ...
   esac

   # In main() function:
   fish)
       symlink_file "$DOTFILES_DIR/shells/fish/config.fish" \
                    "$HOME/.config/fish/config.fish"
       ;;
   ```

4. **Update docs:**
   - Add fish shell prompt example to SHELL_CONFIG.md
   - Note any fish-specific syntax differences

## Security Model

### What's in Version Control

✓ Shell configurations (no secrets)
✓ Git config template (empty email field, relative SSH key paths)
✓ Editor configs
✓ Tool themes and skins

### What's Excluded (.gitignore)

✗ SSH private keys (`id_*`)
✗ Actual email addresses (set locally)
✗ Backup files
✗ OS-specific caches

### Machine-Specific Setup

Users customize locally after installation:

```bash
# After running install.sh:
git config --global user.email "your.email@example.com"
```

Or use installer prompts:

```bash
./scripts/install.sh --ask-secrets
```

## Testing Strategy

| Component     | Test Method                             | Platforms              |
| ------------- | --------------------------------------- | ---------------------- |
| install.sh    | Manual run, verify symlinks             | Linux, macOS           |
| install.ps1   | Manual run in PowerShell 5.1+           | Windows                |
| Shell prompts | `git init && git commit --allow-empty`  | bash, zsh, PowerShell  |
| Git hooks     | `git commit -m "bad msg"` (should fail) | All                    |
| Git config    | `git config --list --show-origin`       | All                    |
| k9s skin      | `k9s` → check colors                    | All (if k9s installed) |

## Future Improvements

1. **chezmoi migration** — If managing 10+ machines, consider migrating to chezmoi for:
   - Template-based configs (personalization)
   - Encrypted secrets
   - Multi-machine state management

2. **More shells** — Add fish, zsh completions, tcsh

3. **Additional tools** — nvim, tmux, lazygit, fzf, starship

4. **Docker/container support** — Dockerfile for development environment

5. **CI/CD validation** — GitHub Actions to test installers on multiple platforms

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on:

- Code style
- Testing requirements
- Documentation standards
- Commit message conventions

---

**Last Updated:** 2026-06-16
