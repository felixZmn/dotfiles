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

    if (!(Test-Path $profilePath)) {
        New-Item -Path $profilePath -ItemType File -Force | Out-Null
    }

    $content = Get-Content $profilePath -Raw

    if ($content -notmatch [regex]::Escape($marker)) {
        Add-Content $profilePath "`n$marker`n. `"$dotfilesAliases`"`n# <<< dotfiles <<<"
        Write-Host "  Updated PowerShell profile"
    } else {
        Write-Host "  Profile already configured, skipping"
    }
}
