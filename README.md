# dotfiles

Cross-platform shell, git, vim, and k9s configs for Linux, macOS, and Windows.

## Quick Start

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
./scripts/install.sh
```

```powershell
# Windows (PowerShell 5.1+)
git clone https://github.com/YOUR_USERNAME/dotfiles.git $env:USERPROFILE\dotfiles
cd $env:USERPROFILE\dotfiles
.\scripts\install.ps1
```

The installer layers configs on top of your existing shell — existing aliases
and settings are preserved via sentinel-guarded bootstrap blocks.

### Options

| Flag            | Description                      |
| --------------- | -------------------------------- |
| `--bash`        | Force bash install               |
| `--ask-secrets` | Prompt for git email and SSH key |
| `--force`       | Overwrite without backup         |
| `--target-user` | Specify user for Windows install |

## License

MIT
