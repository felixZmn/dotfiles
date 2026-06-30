function Deploy($src, $dest) {
    $parent = Split-Path $dest

    if (!(Test-Path $parent)) { New-Item -ItemType Directory -Path $parent | Out-Null }

    if (Test-Path $dest) {
        Remove-Item $dest -Force
    }

    New-Item -ItemType HardLink -Path $dest -Target $src | Out-Null

    Write-Host "  Hardlinked $dest"

}

function DeployDir($srcDir, $destDir) {
    # Directories can't be hardlinked — deploy files individually

    Get-ChildItem $srcDir -File -Recurse | ForEach-Object {
        $relative = $_.FullName.Substring($srcDir.Length)
        Deploy $_.FullName "$destDir$relative"
    }

}

function InjectProfile($profilePath, $dotfilesAliases) {
    $marker = "# >>> dotfiles >>>"
    $parent = Split-Path $profilePath

    if (!(Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (!(Test-Path $profilePath)) {
        New-Item -Path $profilePath -ItemType File -Force | Out-Null
    }

    # Get-Content -Raw returns $null on empty files; $null -notmatch is $false and skips injection.
    $content = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) { $content = "" }

    if ($content -notmatch [regex]::Escape($marker)) {
        $block = @"

$marker
. "$dotfilesAliases"
# <<< dotfiles <<<
"@
        if ($content.Trim().Length -eq 0) {
            Set-Content -Path $profilePath -Value $block.TrimStart() -NoNewline
        } else {
            Add-Content -Path $profilePath -Value $block
        }
        Write-Host "  Updated PowerShell profile: $profilePath"
    } else {
        Write-Host "  Profile already configured, skipping: $profilePath"
    }
}
