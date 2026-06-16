# Felix's Dotfiles

A cross-platform dotfiles repository for managing shell, git, vim, and k9s configurations across Linux, macOS, and Windows.

## Features

- **Git-aware shell prompts** — Shows branch, ahead/behind status, staged/unstaged changes
- **Cross-platform** — Bash, Zsh, and PowerShell with identical behavior
- **Git integration** — Conventional commit hooks, signing, and VS Code diff/merge tools
- **Modular structure** — Easy to extend with new tools and configurations
- **Automated installation** — One-command setup per platform with safe backups
- **Security-first** — SSH signing keys, GPG/SSH commit signing, and sensitive data exclusion

## Quick Start

### Linux / macOS

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x scripts/install.sh
./scripts/install.sh

# Restart shell or source config
source ~/.bashrc   # for bash
source ~/.zshrc    # for zsh
```

### Windows (PowerShell 5.1+)

```powershell
git clone https://github.com/YOUR_USERNAME/dotfiles.git $env:USERPROFILE\dotfiles
cd $env:USERPROFILE\dotfiles
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\install.ps1

# Restart PowerShell or reload profile
. $PROFILE
```

## Installation Options

### Basic Installation

```bash
./scripts/install.sh              # bash/zsh auto-detect
./scripts/install.sh --bash       # force bash
./scripts/install.sh --zsh        # force zsh
```

### Advanced Options

```bash
./scripts/install.sh --ask-secrets    # Prompt for git email and SSH key
./scripts/install.sh --force          # Overwrite existing without backup
./scripts/install.sh --ask-secrets --force
```

## Repository Structure

```
dotfiles/
├── shells/                 # Shell configurations
│   ├── bash/              # Bash shell config
│   ├── zsh/               # Zsh shell config
│   └── powershell/        # PowerShell config
├── git/                   # Git configuration
│   ├── .gitconfig         # Git config (signed commits, tools, aliases)
│   └── hooks/             # Git commit hooks
│       └── commit-msg     # Conventional commit validation
├── vim/                   # Vim configuration
│   └── .vimrc             # Vim config (plugins, keybindings, formatting)
├── tools/                 # Tool-specific configurations
│   └── k9s/               # Kubernetes TUI (k9s) skin
├── scripts/               # Installation and utility scripts
│   ├── install.sh         # Linux/macOS installer
│   ├── install.ps1        # Windows installer
│   └── detect-env.sh      # Environment detection helper
├── docs/                  # Documentation
│   ├── ARCHITECTURE.md    # Project structure and design
│   ├── GIT_CONFIG.md      # Git configuration explained
│   └── SHELL_CONFIG.md    # Shell prompt and configuration
├── .gitignore             # Files to exclude from version control
├── README.md              # This file
├── LICENSE                # MIT License
└── CONTRIBUTING.md        # Contribution guidelines
```

## What Each Config Does

### Shells (.bashrc / .zshrc / profile.ps1)

**Purpose:** Bash, Zsh, and PowerShell configurations with git-aware prompts

**Features:**

- Displays current git branch in yellow
- Shows `↑N` (green) if commits are ahead of upstream
- Shows `↓N` (red) if commits are behind upstream
- Shows `+N` (green) for staged files
- Shows `~` (red) for unstaged modifications
- Shows `?N` (PowerShell only) for untracked files

**Customization:** Edit shell color codes in the prompt section (ANSI escape sequences)

### Git (.gitconfig)

**Purpose:** Git configuration with signing, tools, and conventional commit hook support

**Features:**

- SSH commit signing (requires SSH key setup)
- VS Code integration for diffs and merges
- Custom log alias with commit signature verification
- Conventional commit hook validation
- Automatic main branch as default
- Git rebase on pull (no merge commits)

**Customization:**

- Edit user name and email
- Update SSH signing key path if different
- Change editor (default: vim)

### Git Hooks (hooks/commit-msg)

**Purpose:** Validate commit messages against conventional commit format

**Enforces:** `<type>(<scope>): message`

**Valid types:** build, change, chore, ci, docs, feat, fix, perf, refactor, revert, style, test

**Example:**

```bash
fix(auth): handle login timeout
feat(api): add user profile endpoint
docs: update setup instructions
```

### Vim (.vimrc)

**Purpose:** Vim editor configuration with productivity settings

**Features:**

- 2-space indentation
- Line numbers and column ruler (80 chars)
- Syntax highlighting
- Smart search (case-insensitive with smart caps detection)
- Auto-closing braces and quotes
- System clipboard integration
- Wildmenu for command completion

**Plugins:** Ready to use vim-plug; uncomment `call plug#begin()` to add plugins

### k9s Skin (tools/k9s/skin.yaml)

**Purpose:** Kubernetes TUI (k9s) color theme using Catppuccin Latte palette

**Installation:** Automatically installed if k9s is detected; symlinked to `~/.config/k9s/skins/`

## Configuration

### Customize Your Shell Prompt

Edit the appropriate shell file:

```bash
# For bash: shells/bash/.bashrc
# For zsh:  shells/zsh/.zshrc
# For PowerShell: shells/powershell/profile.ps1
```

**Color codes (ANSI):**

- `1;32m` = Bold Green
- `1;33m` = Bold Yellow
- `1;34m` = Bold Blue
- `1;31m` = Bold Red

### Update Git Configuration

```bash
# User info
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# SSH signing key
git config --global user.signingKey /path/to/ssh/key.pub

# Allow SSH to sign (if not set during install)
git config --global gpg.format ssh
```

### Add New Tools

To add a new tool configuration:

1. Create folder: `tools/<tool-name>/`
2. Add config files (e.g., `tools/nvim/init.vim`)
3. Update `scripts/install.sh` to symlink the new config
4. Document in relevant docs file
5. Commit and push

Example:

```bash
mkdir -p tools/tmux
# Create tools/tmux/tmux.conf
# Update install.sh with symlink logic
```

## Troubleshooting

### Git hook not running

**Symptom:** Commit messages aren't validated despite installing hooks

**Solution:** Verify hook installation:

```bash
git config --global core.hooksPath
# Should output: /path/to/dotfiles/git/hooks

# Make hooks executable (Linux/macOS)
chmod +x git/hooks/*
```

### PowerShell profile not loading

**Symptom:** PowerShell profile settings aren't applied

**Solution:**

1. Check execution policy:
   ```powershell
   Get-ExecutionPolicy
   ```
2. If "Restricted", run:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
3. Reload profile:
   ```powershell
   . $PROFILE
   ```

### Wrong shell detected on install

**Solution:** Force a specific shell during installation:

```bash
./scripts/install.sh --bash   # Force bash
./scripts/install.sh --zsh    # Force zsh
```

### Symlink permission errors (Windows)

**Symptom:** "Access is denied" when creating symlinks

**Solution:** Run PowerShell as Administrator:

```powershell
# In admin PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\scripts\install.ps1
```

## Syncing Across Machines

To keep dotfiles in sync across multiple machines:

```bash
# On any machine
cd ~/dotfiles
git pull origin main

# Re-run installer if configs changed
./scripts/install.sh
```

## Security & Sensitive Data

The `.gitignore` excludes:

- SSH keys (`id_*`, `*.pem`, `*.key`)
- Known hosts files
- Backup and temporary files
- OS-specific files

**Important:** Never commit SSH private keys or passwords. Use:

- Environment variables for secrets
- `git config --global --local` for machine-specific settings
- Git credential helpers for authentication

## Further Documentation

- [ARCHITECTURE.md](docs/ARCHITECTURE.md) — Project structure and design decisions
- [GIT_CONFIG.md](docs/GIT_CONFIG.md) — Detailed git configuration guide
- [SHELL_CONFIG.md](docs/SHELL_CONFIG.md) — Shell prompt design and customization
- [CONTRIBUTING.md](CONTRIBUTING.md) — How to contribute improvements

## License

MIT License — See [LICENSE](LICENSE) for details

## Support

For issues, questions, or suggestions:

1. Check [Troubleshooting](#troubleshooting) above
2. Review docs in `docs/` folder
3. Check git log for configuration history: `git log --all --oneline`

---

**Last Updated:** 2026-06-16  
**Maintained by:** Felix Zimmermann
