$ErrorActionPreference = "Stop"
$dotfiles = $PSScriptRoot

. "$dotfiles\lib\helpers.ps1"

Write-Host ""
Write-Host "==> Git"
#Deploy "$dotfiles\git\gitconfig"           "$HOME\.gitconfig"
#Deploy "$dotfiles\git\gitignore_global"    "$HOME\.gitignore_global"

Write-Host ""
Write-Host "==> Git Hooks"
#DeployDir "$dotfiles\git\hooks"            "$HOME\.config\git\hooks"

Write-Host ""
Write-Host "==> Vim"
Deploy "$dotfiles\vim\.vimrc"               "$HOME\.vimrc"

Write-Host ""
Write-Host "==> PowerShell"
Deploy "$dotfiles\powershell\aliases.ps1"  "$HOME\.dotfiles\powershell\aliases.ps1"

# Dot-source scripts individually (dirs can't be hardlinked)
DeployDir "$dotfiles\powershell\scripts"   "$HOME\.dotfiles\powershell\scripts"

$dotfilesAliases = "$HOME\.dotfiles\powershell\aliases.ps1"
$profilePaths = @(
    $PROFILE.CurrentUserCurrentHost
    "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
) | Select-Object -Unique

foreach ($profilePath in $profilePaths) {
    InjectProfile $profilePath $dotfilesAliases
}

Write-Host ""
Write-Host "✅ Done! Restart PowerShell to apply changes."
