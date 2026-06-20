# =============================================================================
# kuse.ps1 - Manage multiple kubeconfig files safely (PowerShell Edition)
#
# INSTALL:
#   1. Create configs directory and add kubeconfig files:
#      New-Item -ItemType Directory -Force -Path "$HOME\.kube\configs"
#
#   2. Add this script to your PowerShell profile to make it persistent:
#      notepad $PROFILE
#      # Add the following line to the file:
#      . "C:\path\to\kuse.ps1"
#
# CONFIGURE (optional):
#   $env:KUBE_CONFIGS_DIR = "C:\custom\path"   # default: ~/.kube/configs
#
# USAGE:
#   kuse                  list configs (default)
#   kuse <name>           activate a config
#   kuse -l, --list       list all configs
#   kuse -c, --current    show active config + context
#   kuse -r, --reset      switch back to ~/.kube/config
#   kuse -h, --help       show this help
# =============================================================================

# -- Resolve config dir -------------------------------------------------------
$script:KubeConfigsDir = if ($env:KUBE_CONFIGS_DIR) { 
    $env:KUBE_CONFIGS_DIR 
} else { 
    Join-Path $HOME ".kube" "configs" 
}

# -- Colours ------------------------------------------------------------------
# Disabled automatically when stdout is not a tty (e.g. piped).
$script:IsTTY = -not ([Console]::IsOutputRedirected) -and -not ([Console]::IsErrorRedirected)

if ($script:IsTTY) {
    $script:Colors = @{
        Red    = "`e[0;31m"
        Green  = "`e[0;32m"
        Yellow = "`e[0;33m"
        Blue   = "`e[0;34m"
        Cyan   = "`e[0;36m"
        White  = "`e[0;37m"
        Reset  = "`e[0m"
    }
} else {
    $script:Colors = @{
        Red = ''; Green = ''; Yellow = ''; Blue = ''
        Cyan = ''; White = ''; Reset = ''
    }
}

# -- Low-level print helpers --------------------------------------------------

function Write-KubeColor {
    param(
        [string]$Color, 
        [string]$Message, 
        [switch]$NoNewline
    )
    $c = $script:Colors[$Color]
    $r = $script:Colors.Reset
    
    if ($NoNewline) {
        Write-Host "${c}${Message}${r}" -NoNewline
    } else {
        Write-Host "${c}${Message}${r}"
    }
}

function Write-KubeHeader {
    param([string]$Text)
    Write-KubeColor White $Text
    Write-KubeColor Blue  "--------------------------------------------"
}

# -- Shared helpers -----------------------------------------------------------

function Test-KubeDir {
    if (-not (Test-Path $script:KubeConfigsDir -PathType Container)) {
        Write-KubeColor Red  "✗ Config dir not found: $script:KubeConfigsDir"
        Write-KubeColor Cyan "  New-Item -ItemType Directory -Force -Path '$script:KubeConfigsDir'"
        return $false
    }
    return $true
}

function Find-KubeConfig {
    param([string]$Name)
    
    $base = Join-Path $script:KubeConfigsDir $Name
    $candidates = @($base, "$base.yaml", "$base.yml")
    
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate -PathType Leaf) {
            return $candidate
        }
    }
    return $null
}

function Get-KubeCurrentContext {
    $ctx = & kubectl config current-context 2>$null
    return if ($ctx) { $ctx.Trim() } else { "(none)" }
}

function Get-KubeAllContexts {
    $raw = & kubectl config get-contexts -o name 2>$null
    if (-not $raw) { return "(none)" }
    return ($raw | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Join-String -Separator ", ")
}

# -- Subcommand implementations -----------------------------------------------

function Use-KubeConfig {
    param([string]$Name)
    
    if (-not (Test-KubeDir)) { return }

    $path = Find-KubeConfig -Name $Name
    if (-not $path) {
        Write-KubeColor Red  "✗ Not found: '$Name'"
        Write-KubeColor Cyan "  Run 'kuse --list' to see available configs."
        return
    }

    # This is why the script MUST be dot-sourced!
    $env:KUBECONFIG = $path

    $ctx = Get-KubeCurrentContext
    $allCtx = Get-KubeAllContexts
    $fname = Split-Path $path -Leaf

    Write-KubeColor Green "✓ Active: " -NoNewline
    Write-KubeColor White $fname
    Write-KubeColor Cyan  "  Context : $ctx"
    Write-KubeColor Cyan  "  All ctx : $allCtx"
}

function Show-KubeList {
    if (-not (Test-KubeDir)) { return }

    Write-KubeHeader "Kubeconfig files"
    Write-KubeColor Cyan "  Dir: $script:KubeConfigsDir"
    Write-Host ""

    $files = Get-ChildItem -Path $script:KubeConfigsDir -File -ErrorAction SilentlyContinue

    if (-not $files -or $files.Count -eq 0) {
        Write-KubeColor Yellow "  No configs found."
        Write-KubeColor Cyan   "  Copy kubeconfig files to: $script:KubeConfigsDir"
        return
    }

    foreach ($f in $files) {
        $fname = $f.Name
        if ($f.FullName -eq $env:KUBECONFIG) {
            Write-KubeColor Green  "  ▶  " -NoNewline
            Write-KubeColor White  $fname -NoNewline
            Write-KubeColor Yellow "  ← active"
        } else {
            Write-KubeColor Blue "  ◦  " -NoNewline
            Write-Host $fname
        }
    }
}

function Show-KubeCurrent {
    Write-KubeHeader "Active kubeconfig"

    $kcFile = if ($env:KUBECONFIG) { $env:KUBECONFIG } else { Join-Path $HOME ".kube" "config" }
    Write-KubeColor Cyan "  File   : $kcFile"

    $ctx = & kubectl config current-context 2>$null
    if (-not $ctx) {
        Write-KubeColor Red "  Context: (unavailable)"
        return
    }

    Write-KubeColor Cyan "  Context: $($ctx.Trim())"
    Write-Host ""
    Write-KubeHeader "All contexts in this file"
    & kubectl config get-contexts 2>$null
}

function Reset-KubeConfig {
    $default = Join-Path $HOME ".kube" "config"
    $env:KUBECONFIG = $default

    Write-KubeColor Yellow "↩  Reset to: $default"

    if (-not (Test-Path $default -PathType Leaf)) {
        Write-KubeColor Yellow "  ⚠  File does not exist"
        return
    }

    $ctx = & kubectl config current-context 2>$null
    if ($ctx) {
        Write-KubeColor Cyan "  Context: $($ctx.Trim())"
    }
}

function Show-KubeHelp {
    Write-KubeHeader "kuse — kubernetes config switcher"

    $entries = @(
        @{ Cmd = "<name>";       Desc = "activate a kubeconfig" }
        @{ Cmd = "-l, --list";   Desc = "list all configs (default)" }
        @{ Cmd = "-c, --current";Desc = "show active config + context" }
        @{ Cmd = "-r, --reset";  Desc = "switch back to ~/.kube/config" }
        @{ Cmd = "-h, --help";   Desc = "show this help" }
    )

    foreach ($e in $entries) {
        $cmdPadded = $e.Cmd.PadRight(20)
        Write-KubeColor Cyan "  $cmdPadded" -NoNewline
        Write-Host $e.Desc
    }

    Write-Host ""
    Write-KubeColor Blue   "  Config dir : $script:KubeConfigsDir"
    Write-KubeColor Blue   "  Override   : " -NoNewline
    Write-Host '$env:KUBE_CONFIGS_DIR = "C:\your\path"'
}

# -- Main entry point ---------------------------------------------------------

function kuse {
    param(
        [Parameter(Position = 0)]
        [string]$Name,

        [Alias("l")]
        [switch]$List,

        [Alias("c")]
        [switch]$Current,

        [Alias("r")]
        [switch]$Reset,

        [Alias("h")]
        [switch]$Help
    )

    if ($Help)    { Show-KubeHelp; return }
    if ($Current) { Show-KubeCurrent; return }
    if ($Reset)   { Reset-KubeConfig; return }
    if ($List)    { Show-KubeList; return }

    if ($Name) {
        # Catch unknown switches passed as positional arguments
        if ($Name.StartsWith("-")) {
            Write-KubeColor Red  "✗ Unknown option: '$Name'"
            Write-KubeColor Cyan "  Run 'kuse --help' for usage."
            return
        }
        Use-KubeConfig -Name $Name
        return
    }

    # Default action (no arguments)
    Show-KubeList
    Write-Host ""
    Write-KubeColor Cyan "Tip: kuse <name> to switch  |  kuse --help for all options"
}

# -- Tab completion -----------------------------------------------------------

Register-ArgumentCompleter -CommandName kuse -ParameterName Name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    $candidates = @("--list", "--current", "--reset", "--help", "-l", "-c", "-r", "-h")

    if (Test-Path $script:KubeConfigsDir -PathType Container) {
        $files = Get-ChildItem -Path $script:KubeConfigsDir -File
        foreach ($f in $files) {
            $candidates += $f.Name
        }
    }

    $candidates | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
    }
}
