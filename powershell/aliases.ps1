$dotscripts = "$HOME\.dotfiles\powershell\scripts"  # direct, no copy needed since hardlinked

# Auto-dot-source all function scripts
Get-ChildItem "$dotscripts\*.ps1" | ForEach-Object {
  . $_.FullName
}

# Add executables to PATH
$env:PATH = "$dotscripts\bin;$env:PATH"