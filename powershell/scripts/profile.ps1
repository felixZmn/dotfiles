Set-Alias k kubectl

# bash-like autocomplete
Set-PSReadlineKeyHandler -Key Tab -Function Complete
Set-PSReadlineOption -BellStyle None

# -- Git status cache ---------------------------------------------------------
$script:_GitCache    = $null
$script:_GitCacheDir = ""
$script:_GitCacheAge = [datetime]::MinValue

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
    $cwd = (Get-Location).Path
    $now = [datetime]::UtcNow

    # Return cached result if we're in the same directory and cache is fresh.
    if (
        $script:_GitCacheDir -eq $cwd -and
        ($now - $script:_GitCacheAge).TotalSeconds -lt 5
    ) {
        return $script:_GitCache
    }

    $statusOutput = git status --porcelain=v2 --branch 2>$null

    # Cache a $null result too, so we don't keep retrying outside git repos.
    if ($null -eq $statusOutput) {
        $script:_GitCache = $null
        $script:_GitCacheDir = $cwd
        $script:_GitCacheAge = $now
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

    $result = @{
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

    $script:_GitCache    = $result
    $script:_GitCacheDir = $cwd
    $script:_GitCacheAge = $now

    return $result
}

function prompt {
    $gitStatus = Get-GitStatus
    $kubeContext = Get-KubeContext

    # 1. Write the Path
    Write-Host "PS $((Get-Location).Path)" -NoNewline -ForegroundColor Cyan

    # 2. Write Kubernetes context
    if ($kubeContext) {
        Write-Host " [☸ $kubeContext]" -NoNewline -ForegroundColor Blue
    }

    if ($gitStatus) {
        # 3. Write the Branch Name
        Write-Host " [$($gitStatus.Branch)" -NoNewline -ForegroundColor Yellow

        # 4. Write Up/Down counts
        if ($gitStatus.Ahead -gt 0) {
            Write-Host " ↑$($gitStatus.Ahead)" -NoNewline -ForegroundColor Green
        }

        if ($gitStatus.Behind -gt 0) {
            Write-Host " ↓$($gitStatus.Behind)" -NoNewline -ForegroundColor Red
        }

        Write-Host "]" -NoNewline -ForegroundColor Yellow

        # 5. Write File Changes
        if ($gitStatus.Staged -gt 0) {
            Write-Host " +$($gitStatus.Staged)" -NoNewline -ForegroundColor Green
        }

        if ($gitStatus.Modified -gt 0) {
            Write-Host " ~$($gitStatus.Modified)" -NoNewline -ForegroundColor Red
        }

        if ($gitStatus.Untracked -gt 0) {
            Write-Host " ?$($gitStatus.Untracked)" -NoNewline -ForegroundColor Magenta
        }
    }

    # 6. Return the final prompt marker
    return "> "
}

# source various helper scripts
$dotfilesRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. "$dotfilesRoot\powershell\scripts\kuse.ps1"
Remove-Variable dotfilesRoot
