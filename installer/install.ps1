# Usage: .\scripts\install.ps1 [-AskSecrets] [-Force] [-Verbose]
# Requirements: PowerShell 5.1+

[CmdletBinding()]
param(
    [switch]$AskSecrets,
    [switch]$Force,
)

$ErrorActionPreference = "Stop"
$InformationPreference = if ($Verbose) { "Continue" } else { "SilentlyContinue" }

# ============================================================================
# Configuration
# ============================================================================
$DotfilesDir = Split-Path -Parent $PSScriptRoot
$BackupDir = Join-Path $env:USERPROFILE ".dotfiles-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
# Use $PROFILE directly (the actual loadable profile path, e.g.
# Microsoft.PowerShell_profile.ps1). The previous code computed $ProfileDir
# from $PROFILE but then wrote a hardcoded "profile.ps1" that PowerShell
# never loaded.
$ProfilePath = if ($PROFILE) { $PROFILE } else { Join-Path $env:USERPROFILE "Documents\PowerShell\Microsoft.PowerShell_profile.ps1" }

# ============================================================================
# Helper functions
# ============================================================================
function Write-Log {
    param([string]$Message, [ValidateSet("Info", "Success", "Warn", "Error")]$Level = "Info")
    
    $color = @{
        Info    = "Cyan"
        Success = "Green"
        Warn    = "Yellow"
        Error   = "Red"
    }[$Level]
    
    $prefix = @{
        Info    = "ℹ"
        Success = "✓"
        Warn    = "⚠"
        Error   = "✗"
    }[$Level]
    
    Write-Host "$prefix " -ForegroundColor $color -NoNewline
    Write-Host $Message
}

function Backup-File {
    param([string]$Path)
    
    if (Test-Path $Path) {
        if ($Force) {
            Write-Log "Removing existing $Path (force mode)" "Warn"
            Remove-Item -Path $Path -Recurse -Force
        } else {
            if (-not (Test-Path $BackupDir)) {
                New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
            }
            Write-Log "Backing up $Path to $BackupDir\" "Info"
            Copy-Item -Path $Path -Destination $BackupDir -Recurse -Force
        }
    }
}

function New-SymLink {
    param(
        [string]$SourcePath,
        [string]$TargetPath
    )

    Backup-File -Path $TargetPath

    $targetDir = Split-Path -Parent $TargetPath
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    New-Item -ItemType SymbolicLink -Path $TargetPath -Target $SourcePath -Force | Out-Null
    Write-Log "Linked $TargetPath -> $SourcePath" "Success"
}

function Test-SymLinkSupport {
    try {
        $tmp = Join-Path $env:TEMP "dotfiles_symlink_test"
        New-Item -ItemType SymbolicLink -Path $tmp -Target $env:TEMP -Force -ErrorAction Stop | Out-Null
        Remove-Item $tmp -Force
        return $true
    } catch {
        return $false
    }
}

# Append a dotfiles bootstrap snippet to the user's PowerShell profile without
# overwriting it. The snippet is sentinel-guarded, so re-running the installer
# is safe (idempotent). The user's existing profile content is preserved
# verbatim; the dotfiles version is dot-sourced on top.
function Install-ShellBootstrap {
    param(
        [string]$TargetPath,   # e.g. $PROFILE
        [string]$SnippetPath   # e.g. dotfiles/shells/powershell/profile_dotfiles_snippet.ps1
    )

    $sentinel = "# >>> dotfiles bootstrap >>>"

    if (-not (Test-Path $SnippetPath)) {
        Write-Log "Bootstrap snippet not found: $SnippetPath" "Error"
        throw "Bootstrap snippet not found: $SnippetPath"
    }

    $targetDir = Split-Path -Parent $TargetPath
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    if (-not (Test-Path $TargetPath)) {
        New-Item -ItemType File -Path $TargetPath -Force | Out-Null
    }

    $existing = Get-Content -Path $TargetPath -Raw -ErrorAction SilentlyContinue
    if ($existing -and $existing.Contains($sentinel)) {
        Write-Log "Bootstrap already present in $TargetPath (skipping)" "Info"
        return
    }

    # Substitute __DOTFILES_DIR__ with the absolute dotfiles path so the
    # snippet works regardless of where the user cloned the repo.
    $rendered = Get-Content -Path $SnippetPath -Raw `
        -ErrorAction SilentlyContinue
    if ($null -eq $rendered) {
        Write-Log "Bootstrap snippet is empty: $SnippetPath" "Error"
        return
    }
    $rendered = $rendered.Replace('__DOTFILES_DIR__', $DotfilesDir)

    A$rendered = $rendered -replace "`r`n", "`n"
    [System.IO.File]::AppendAllText($TargetPath, "`n$rendered")
    Write-Log "Appended dotfiles bootstrap to $TargetPath" "Success"
}

# ============================================================================
# Main installation
# ============================================================================
function Install-Dotfiles {
    if (-not (Test-SymLinkSupport)) {
        Write-Log "Symlinks require Administrator rights or Developer Mode. Re-run as Administrator." "Error"
        exit 1
    }

    Write-Log "Starting dotfiles installation..." "Info"
    Write-Log "PowerShell version: $($PSVersionTable.PSVersion)" "Info"
    
    # Git configuration
    Write-Log "Installing git configuration..." "Info"
    New-SymLink -SourcePath (Join-Path $DotfilesDir "git\.gitconfig") -TargetPath (Join-Path $env:USERPROFILE ".gitconfig")
    
    # PowerShell profile
    # NOTE: We do NOT symlink $PROFILE — that would overwrite any user
    # customizations. Instead, we append a small bootstrap snippet that
    # dot-sources the dotfiles version. Also: target $PROFILE directly so
    # PowerShell actually loads it (the previous code wrote a hardcoded
    # "profile.ps1" that was never sourced).
    Write-Log "Installing PowerShell profile..." "Info"
    Install-ShellBootstrap `
        -TargetPath $ProfilePath `
        -SnippetPath (Join-Path $DotfilesDir "shells\powershell\profile_dotfiles_snippet.ps1")
    
    # Vim configuration (if available)
    if ((Get-Command vim -ErrorAction SilentlyContinue) -or (Get-Command nvim -ErrorAction SilentlyContinue)) {
        Write-Log "Installing vim configuration..." "Info"
        New-SymLink -SourcePath (Join-Path $DotfilesDir "vim\.vimrc") -TargetPath (Join-Path $env:USERPROFILE ".vimrc")
    } else {
        Write-Log "Vim not found, skipping vim configuration" "Warn"
    }
    
    # Git hooks
    Write-Log "Configuring git hooks..." "Info"
    $hookPath = Join-Path $DotfilesDir "git\hooks"
    & git config --global core.hooksPath $hookPath
    Write-Log "Git hooks configured via core.hooksPath" "Success"
    
    # k9s configuration (if installed)
    if (Get-Command k9s -ErrorAction SilentlyContinue) {
        Write-Log "Installing k9s skin..." "Info"
        $k9sDir = Join-Path $env:APPDATA "k9s\skins"
        New-Item -ItemType Directory -Path $k9sDir -Force | Out-Null
        New-SymLink -SourcePath (Join-Path $DotfilesDir "tools\k9s\skin.yaml") -TargetPath (Join-Path $k9sDir "catppuccin-custom.yaml")
    } else {
        Write-Log "k9s not found, skipping k9s configuration" "Warn"
    }
    
    # Interactive prompt for secrets (optional)
    if ($AskSecrets) {
        Write-Log "Configuring git user settings..." "Info"
        
        $currentEmail = & git config --global user.email 2>&1
        if ($LASTEXITCODE -ne 0) { $currentEmail = "not set" }
        $email = Read-Host "Git user email (current: $currentEmail)"
        if ($email) {
            & git config --global user.email $email
            Write-Log "Git email set to: $email" "Success"
        }
        
        $currentSigningKey = & git config --global user.signingKey 2>&1
        $signingKey = Read-Host "SSH signing key path (current: $currentSigningKey)"
        if ($signingKey) {
            & git config --global user.signingKey $signingKey
            Write-Log "SSH signing key set to: $signingKey" "Success"
        }
    }
    
    Write-Host ""
    Write-Log "Installation complete!" "Success"
    Write-Host ""
    Write-Log "Summary:" "Info"
    Write-Host "  - Git config: $env:USERPROFILE\.gitconfig"
    Write-Host "  - PowerShell profile: $ProfilePath (bootstrap appended)"
    Write-Host "  - Vim config: $env:USERPROFILE\.vimrc"
    Write-Host "  - Git hooks: $hookPath"

    if (Test-Path $BackupDir) {
        Write-Host "  - Backups: $BackupDir"
    }

    Write-Host ""
    Write-Log "Next steps:" "Info"
    Write-Host "  1. Restart PowerShell or run: . `$PROFILE"
    Write-Host "  2. Test git status in a repo: git status"
    Write-Host "  3. (Optional) Configure git email: git config --global user.email 'your.email@example.com'"
    Write-Host ""
    Write-Log "To uninstall the dotfiles layer, delete the block between" "Info"
    Write-Host "  '# >>> dotfiles bootstrap >>>' and '# <<< dotfiles bootstrap <<<'"
    Write-Host "  in your PowerShell profile."
}

# ============================================================================
# Run installation
# ============================================================================
Install-Dotfiles
