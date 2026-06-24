# Usage: .\scripts\install.ps1 [-AskSecrets] [-Force] [-TargetUser <username>] [-Verbose]
# Requirements: PowerShell 5.1+ (No Admin rights required!)

[CmdletBinding()]
param(
    [switch]$AskSecrets,
    [switch]$Force,
    [string]$TargetUser 
)

$ErrorActionPreference = "Stop"
$InformationPreference = if ($PSBoundParameters.ContainsKey('Verbose')) { "Continue" } else { "SilentlyContinue" }

# ============================================================================
# Configuration & Context Resolution
# ============================================================================
$DotfilesDir = Split-Path -Parent $PSScriptRoot
$BackupDir = Join-Path $env:USERPROFILE ".dotfiles-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"

# If running elevated as a different admin user, resolve the target user's paths
if ($TargetUser) {
    Write-Host "Resolving profile for target user: $TargetUser..." -ForegroundColor Magenta
    try {
        $sid = (New-Object System.Security.Principal.NTAccount($TargetUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
        $resolvedProfilePath = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList\$sid" -ErrorAction Stop).ProfileImagePath
        $env:USERPROFILE = $resolvedProfilePath
    } catch {
        Write-Host "Could not resolve via registry, falling back to standard path." -ForegroundColor Yellow
        $env:USERPROFILE = "C:\Users\$TargetUser"
    }
}

$ProfilePath = if ($PROFILE -and -not $TargetUser) { 
    $PROFILE 
} else { 
    Join-Path $env:USERPROFILE "Documents\PowerShell\Microsoft.PowerShell_profile.ps1" 
}

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

function New-SmartLink {
    <#
    .SYNOPSIS
    Creates links WITHOUT requiring Admin rights.
    Uses Hardlinks for files, and Junctions for directories.
    Falls back to Copy if Hardlink fails (e.g., cross-volume).
    #>
    param(
        [string]$SourcePath,
        [string]$TargetPath
    )

    Backup-File -Path $TargetPath

    $targetDir = Split-Path -Parent $TargetPath
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    $isDir = (Get-Item $SourcePath).PSIsContainer

    if ($isDir) {
        # Junctions do not require admin rights and work across volumes
        New-Item -ItemType Junction -Path $TargetPath -Target $SourcePath -Force | Out-Null
        Write-Log "Linked (Junction) $TargetPath -> $SourcePath" "Success"
    } else {
        try {
            # Hardlinks do not require admin rights (same volume only)
            New-Item -ItemType HardLink -Path $TargetPath -Target $SourcePath -Force -ErrorAction Stop | Out-Null
            Write-Log "Linked (Hardlink) $TargetPath -> $SourcePath" "Success"
        } catch {
            # Fallback for cross-volume drives (e.g. Dotfiles on C:, User on D:)
            Copy-Item -Path $SourcePath -Destination $TargetPath -Force
            Write-Log "Copied (Hardlink failed/cross-volume) $TargetPath <- $SourcePath" "Warn"
        }
    }
}

function Get-RenderedBootstrap {
    param([string]$SnippetPath)

    if (-not (Test-Path $SnippetPath)) {
        Write-Log "Bootstrap snippet not found: $SnippetPath" "Error"
        throw "Bootstrap snippet not found: $SnippetPath"
    }

    $rendered = Get-Content -Path $SnippetPath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $rendered) {
        Write-Log "Bootstrap snippet is empty: $SnippetPath" "Error"
        throw "Bootstrap snippet is empty: $SnippetPath"
    }

    $rendered = $rendered.Replace('__DOTFILES_DIR__', $DotfilesDir)
    return ($rendered -replace "`r`n", "`n").TrimEnd()
}

function Install-ShellBootstrap {
    param(
        [string]$TargetPath,
        [string]$SnippetPath
    )

    $sentinelStart = "# >>> dotfiles bootstrap >>>"
    $sentinelEnd = "# <<< dotfiles bootstrap <<<"
    $bootstrapBlockPattern = "(?s)\r?\n# >>> dotfiles bootstrap >>>.*?# <<< dotfiles bootstrap <<<"

    $rendered = Get-RenderedBootstrap -SnippetPath $SnippetPath

    $targetDir = Split-Path -Parent $TargetPath
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }
    if (-not (Test-Path $TargetPath)) {
        New-Item -ItemType File -Path $TargetPath -Force | Out-Null
    }

    $existing = Get-Content -Path $TargetPath -Raw -ErrorAction SilentlyContinue
    if ($existing -and $existing.Contains($sentinelStart)) {
        $updated = [regex]::Replace($existing, $bootstrapBlockPattern, "`n$rendered")
        [System.IO.File]::WriteAllText($TargetPath, $updated.TrimEnd() + "`n")
        Write-Log "Updated dotfiles bootstrap in $TargetPath" "Success"
        return
    }

    [System.IO.File]::AppendAllText($TargetPath, "`n$rendered`n")
    Write-Log "Appended dotfiles bootstrap to $TargetPath" "Success"
}

# ============================================================================
# Main installation
# ============================================================================
function Install-Dotfiles {
    # Removed Admin check because Hardlinks/Junctions don't require it!

    Write-Log "Starting dotfiles installation..." "Info"
    Write-Log "PowerShell version: $($PSVersionTable.PSVersion)" "Info"
    Write-Log "Installing to User Profile: $env:USERPROFILE" "Info"
    
    # Git configuration
    Write-Log "Installing git configuration..." "Info"
    New-SmartLink -SourcePath (Join-Path $DotfilesDir "git\.gitconfig") -TargetPath (Join-Path $env:USERPROFILE ".gitconfig")
    
    # PowerShell profile (all-hosts — works in Console, VS Code, Cursor, etc.)
    Write-Log "Installing PowerShell profile..." "Info"
    $snippetPath = Join-Path $DotfilesDir "shells\powershell\profile_dotfiles_snippet.ps1"
    Install-ShellBootstrap -TargetPath $ProfilePath -SnippetPath $snippetPath
    
    # Vim configuration (if available)
    if ((Get-Command vim -ErrorAction SilentlyContinue) -or (Get-Command nvim -ErrorAction SilentlyContinue)) {
        Write-Log "Installing vim configuration..." "Info"
        New-SmartLink -SourcePath (Join-Path $DotfilesDir "vim\.vimrc") -TargetPath (Join-Path $env:USERPROFILE ".vimrc")
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
        New-SmartLink -SourcePath (Join-Path $DotfilesDir "tools\k9s\skin.yaml") -TargetPath (Join-Path $k9sDir "catppuccin-custom.yaml")
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
