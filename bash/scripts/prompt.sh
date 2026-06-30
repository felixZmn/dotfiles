git_info() {
    local status_output result
    status_output=$(git status --porcelain=v2 --branch 2>/dev/null)

    [[ -n "$status_output" ]] || return

    local branch_name="" ahead=0 behind=0 staged=0 modified=0 untracked=0
    local line char
    local R=$'\001' N=$'\002' E=$'\033'  # \[, \], and ESC for PS0

    # Parse porcelain=v2 output — mirrors Get-GitStatus in profile.ps1.
    while IFS= read -r line; do
        if [[ "$line" == \#* ]]; then
            if [[ "$line" =~ ^#\ branch\.head\ (.*)$ ]]; then
                branch_name="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^#\ branch\.ab\ \+([0-9]+)\ -([0-9]+) ]]; then
                ahead="${BASH_REMATCH[1]}"
                behind="${BASH_REMATCH[2]}"
            fi
        else
            char="${line:0:1}"

            if [[ "$char" == "?" ]]; then
                ((untracked++)) || true
            elif [[ "$char" == "u" ]]; then
                ((modified++)) || true
            elif [[ "$char" == "1" || "$char" == "2" ]]; then
                [[ "${line:2:1}" != "." ]] && ((staged++)) || true
                [[ "${line:3:1}" != "." ]] && ((modified++)) || true
            fi
        fi
    done <<< "$status_output"

    result=""

    # Branch name — bold yellow (1;33)
    result+="${R}${E}[1;33m${N} [${branch_name}"

    # Ahead — bold green (1;32)
    if (( ahead > 0 )); then
        result+=" ${R}${E}[1;32m${N}↑${ahead}"
    fi

    # Behind — bold red (1;31)
    if (( behind > 0 )); then
        result+=" ${R}${E}[1;31m${N}↓${behind}"
    fi

    # Close bracket — bold yellow (1;33)
    result+="${R}${E}[1;33m${N}]"

    # Staged — bold green (1;32)
    if (( staged > 0 )); then
        result+=" ${R}${E}[1;32m${N}+${staged}"
    fi

    # Modified — bold red (1;31)
    if (( modified > 0 )); then
        result+=" ${R}${E}[1;31m${N}~${modified}"
    fi

    # Untracked — magenta (35)
    if (( untracked > 0 )); then
        result+=" ${R}${E}[35m${N}?${untracked}"
    fi

    result+="${R}${E}[0m${N}"

    printf "%s" "$result"
}

kube_info() {
    local kubeconfig_path ctx

    # Mirror kuse.sh's logic: honour $KUBECONFIG, fall back to default.
    kubeconfig_path="${KUBECONFIG:-$HOME/.kube/config}"

    [[ -f "$kubeconfig_path" ]] || return 0

    ctx=$(grep -m1 "^current-context:" "$kubeconfig_path" \
          | sed 's/^current-context:[[:space:]]*//')

    [[ -n "$ctx" ]] || return 0

    # Bold Cyan, visually distinct from the git colors
    printf "\001\033[1;36m\002 [☸ %s]\001\033[0m\002" "$ctx"
}

userHost="\[\e[1;32m\]\u\[\e[m\]\[\e[1;32m\]@\[\e[m\]\[\e[1;32m\]\h\[\e[m\]"
path="\[\e[1;34m\]\w\[\e[m\]"

PS1="$userHost:$path\$(kube_info)\$(git_info) \\$ "
