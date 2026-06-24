# >>> dotfiles bootstrap >>>
# Dot-source the dotfiles PowerShell profile if it exists. This block is
# appended by scripts/install.ps1 and is idempotent (re-running the installer
# is safe). To uninstall, delete this block.
#
# Guard uses Get-Command (session scope) — not an env var — so launching
# VS Code/Cursor from a terminal that already loaded the profile does not
# skip loading in new integrated-terminal sessions.
if (-not (Get-Command kuse -ErrorAction SilentlyContinue) -and (Test-Path "__DOTFILES_DIR__\shells\powershell\profile.ps1")) {
    . "__DOTFILES_DIR__\shells\powershell\profile.ps1"
}
# <<< dotfiles bootstrap <<<
