# install.ps1 - Windows PowerShell installer for Felix's dotfiles
# Usage: .\scripts\install.ps1 [-AskSecrets] [-Force] [-Verbose]
# Requirements: PowerShell 5.1+

param(
    [switch]$AskSecrets,
    [switch]$Force,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$InformationPreference = if ($Verbose) { "Continue" } else { "SilentlyContinue" }

# ============================================================================
# Configuration
# ============================================================================
$DotfilesDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$BackupDir = Join-Path $env:USERPROFILE ".dotfiles-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$ProfileDir = if ($PROFILE) { Split-Path $PROFILE } else { Join-Path $env:USERPROFILE "Documents\PowerShell" }

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

# ============================================================================
# Main installation
# ============================================================================
function Install-Dotfiles {
    Write-Log "Starting dotfiles installation..." "Info"
    Write-Log "PowerShell version: $($PSVersionTable.PSVersion)" "Info"
    
    # Git configuration
    Write-Log "Installing git configuration..." "Info"
    New-SymLink -SourcePath (Join-Path $DotfilesDir "git\.gitconfig") -TargetPath (Join-Path $env:USERPROFILE ".gitconfig")
    
    # PowerShell profile
    Write-Log "Installing PowerShell profile..." "Info"
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
    $profilePath = Join-Path $ProfileDir "profile.ps1"
    New-SymLink -SourcePath (Join-Path $DotfilesDir "shells\powershell\profile.ps1") -TargetPath $profilePath
    
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
        
        $currentEmail = (& git config --global user.email) 2>$null
        $email = Read-Host "Git user email (current: $currentEmail)"
        if ($email) {
            & git config --global user.email $email
            Write-Log "Git email set to: $email" "Success"
        }
        
        $currentSigningKey = (& git config --global user.signingKey) 2>$null
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
    Write-Host "  - PowerShell profile: $profilePath"
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
}

# ============================================================================
# Run installation
# ============================================================================
Install-Dotfiles
