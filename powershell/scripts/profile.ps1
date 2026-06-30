Set-Alias k kubectl

# bash-like autocomplete
Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadlineOption -BellStyle None

function Get-KubeContext {
    # Resolve which kubeconfig is active — identical logic to kuse.ps1.
    # Reading a text file is ~1ms vs. ~200ms for spawning kubectl.
    $kubeconfigPath = if ($env:KUBECONFIG) { 
        $env:KUBECONFIG 
    } else { 
        Join-Path $HOME ".kube" "config" 
    }

    if (-not (Test-Path $kubeconfigPath -PathType Leaf)) {
        return $null
    }

    # Parse current-context directly from the YAML — no process spawn needed.
    $line = Select-String -Path $kubeconfigPath -Pattern "^current-context:" |
            Select-Object -First 1

    if (-not $line) { return $null }

    $ctx = ($line.Line -replace "^current-context:\s*", "").Trim()

    if ([string]::IsNullOrWhiteSpace($ctx)) { return $null }

    return $ctx
}

function Get-GitStatus {
    $statusOutput = git status --porcelain=v2 --branch 2>$null

    if ($null -eq $statusOutput) {
        return $null
    }

    $branchName = ""
    $commitHash = ""
    $upstream = $null
    $ahead = 0
    $behind = 0
    $staged = 0
    $modified = 0
    $untracked = 0

    foreach ($line in $statusOutput) {
        if ($line.StartsWith("#")) {
            if ($line -match "^# branch\.head (.*)") {
                $branchName = $matches[1]
            }
            elseif ($line -match "^# branch\.oid (.*)") {
                # Grab first 7 chars for short hash
                $commitHash = $matches[1].Substring(0,7)
            }
            elseif ($line -match "^# branch\.upstream (.*)") {
                $upstream = $matches[1]
            }
            elseif ($line -match "^# branch\.ab \+(\d+) -(\d+)") {
                $ahead = [int]$matches[1]
                $behind = [int]$matches[2]
            }
        } 
        # Lines not starting with # are file changes
        else {
            $char = $line[0]
            
            # '?' is untracked
            if ($char -eq '?') { 
                $untracked++ 
            }
            # 'u' is unmerged/conflict
            elseif ($char -eq 'u') { 
                $modified++ 
            }
            # '1' or '2' are normal changes (XY SUB... format)
            # The second character is the Index (Staged) status
            # The third character is the WorkTree (Modified) status
            elseif ($char -eq '1' -or $char -eq '2') {
                if ($line[2] -ne '.') { $staged++ }
                if ($line[3] -ne '.') { $modified++ }
            }
        }
    }

    return @{
        RepoName   = Split-Path -Leaf $PWD
        Branch     = $branchName
        Hash       = $commitHash
        Upstream   = $upstream
        Ahead      = $ahead
        Behind     = $behind
        Staged     = $staged
        Modified   = $modified
        Untracked  = $untracked
        HasChanges = ($staged + $modified + $untracked) -gt 0
    }
}

function Write-PromptPart {
    param(
        [string]$Text,
        [string]$Ansi  # SGR params, e.g. '1;34' — matches bash prompt.sh
    )
    $esc = [char]27
    Write-Host "${esc}[$Ansi`m$Text${esc}[0m" -NoNewline
}

function prompt {
    $gitStatus = Get-GitStatus
    $kubeContext = Get-KubeContext

    # Path — bold blue (1;34), like bash \w
    Write-PromptPart "PS $((Get-Location).Path)" '1;34'

    # Kubernetes — bold cyan (1;36), like bash kube_info
    if ($kubeContext) {
        Write-PromptPart " [☸ $kubeContext]" '1;36'
    }

    if ($gitStatus) {
        # Branch — bold yellow (1;33)
        Write-PromptPart " [$($gitStatus.Branch)" '1;33'

        if ($gitStatus.Ahead -gt 0) {
            Write-PromptPart " ↑$($gitStatus.Ahead)" '1;32'
        }

        if ($gitStatus.Behind -gt 0) {
            Write-PromptPart " ↓$($gitStatus.Behind)" '1;31'
        }

        Write-PromptPart ']' '1;33'

        if ($gitStatus.Staged -gt 0) {
            Write-PromptPart " +$($gitStatus.Staged)" '1;32'
        }

        if ($gitStatus.Modified -gt 0) {
            Write-PromptPart " ~$($gitStatus.Modified)" '1;31'
        }

        if ($gitStatus.Untracked -gt 0) {
            Write-PromptPart " ?$($gitStatus.Untracked)" '35'
        }
    }

    return "> "
}

# source various helper scripts
$dotfilesRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. "$dotfilesRoot\powershell\scripts\kuse.ps1"
Remove-Variable dotfilesRoot
