# >>> dotfiles bootstrap >>>
# Dot-source the dotfiles PowerShell profile if it exists. This block is
# appended by scripts/install.ps1 and is idempotent (re-running the installer
# is safe). To uninstall, delete this block.
if (-not $env:DOTFILES_PWSH_LOADED -and (Test-Path "__DOTFILES_DIR__\shells\powershell\profile.ps1")) {
    $env:DOTFILES_PWSH_LOADED = "1"
    . "__DOTFILES_DIR__\shells\powershell\profile.ps1"
}
# <<< dotfiles bootstrap <<<