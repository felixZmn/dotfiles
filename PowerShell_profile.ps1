function Get-GitStatus {
    $statusOutput = git status --porcelain=v2 --branch 2>$null

    if ($null -eq $statusOutput) {
        return $null
    }

    # Initialize default values
    $branchName = ""
    $commitHash = ""
    $upstream = $null
    $ahead = 0
    $behind = 0
    
    $staged = 0
    $modified = 0
    $untracked = 0

    # Parse the output line by line
    foreach ($line in $statusOutput) {
        # Lines starting with # are branch info
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
                $x = $line[2] # Staged
                $y = $line[3] # Unstaged

                if ($x -ne '.') { $staged++ }
                if ($y -ne '.') { $modified++ }
            }
        }
    }

    # Return the single object
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

function prompt {
    $gitStatus = Get-GitStatus

    # 1. Write the Path (Cyan)
    Write-Host "PS $((Get-Location).Path)" -NoNewline -ForegroundColor Cyan

    if ($gitStatus) {
        # 2. Write the Branch Name (Yellow)
        Write-Host " [$($gitStatus.Branch)" -NoNewline -ForegroundColor Yellow

        # 3. Write Up/Down counts
        if ($gitStatus.Ahead -gt 0) {
            Write-Host " " -NoNewline -ForegroundColor Green
            Write-Host "↑" -NoNewline -ForegroundColor Green
            Write-Host $gitStatus.Ahead -NoNewline -ForegroundColor Green
        }
        if ($gitStatus.Behind -gt 0) {
            Write-Host " " -NoNewline -ForegroundColor Red
            Write-Host "↓" -NoNewline -ForegroundColor Red
            Write-Host $gitStatus.Behind -NoNewline -ForegroundColor Red
        }

        Write-Host "]" -NoNewline -ForegroundColor Yellow

        # 4. Write File Changes
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

    # 5. Return the final caret
    return "> "
}
