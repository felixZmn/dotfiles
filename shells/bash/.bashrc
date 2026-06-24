# -- Git status cache ---------------------------------------------------------
_git_cache=""
_git_cache_dir=""
_git_cache_time=0

git_info() {
    local now cwd result
    cwd="$PWD"
    now=$(date +%s)

    # Return cached result if we're in the same directory and cache is fresh.
    if [[ "$cwd" == "$_git_cache_dir" && $(( now - _git_cache_time )) -lt 5 ]]; then
        printf "%s" "$_git_cache"
        return
    fi

    result=$(git status --porcelain=v2 --branch 2>/dev/null | awk '
    /^# branch.head/ { b=$3 }
    /^# branch.ab/   { a=$3; d=$4 }
    # Check for Modified/Untracked/Unmerged
    /^[\?u]/         { w=1 }
    /^[12]/          { 
                       if($2 ~ /^[^.]/) s++; # Staged count
                       if($2 ~ /.[^.]/) w=1; # Unstaged flag
                     }
    END {
        if(!b) exit
        
        # Branch: Bold Yellow (1;33)
        printf "\001\033[1;33m\002 [%s", b
        
        # Ahead: Bold Green (1;32)
        if(a>0) printf " \001\033[1;32m\002↑%d", a
        
        # Behind: Bold Red (1;31)
        if(d<0) printf " \001\033[1;31m\002↓%d", d*-1
        
        # Close Bracket: Bold Yellow (1;33)
        printf "\001\033[1;33m\002]"
        
        # Staged: Bold Green (1;32)
        if(s) printf " \001\033[1;32m\002+%d", s
        
        # Dirty (Any unstaged change): Bold Red (1;31)
        if(w) printf " \001\033[1;31m\002~"
        
        # Reset
        printf "\001\033[0m\002"
    }')

    # Cache result — including empty string, so we don't retry outside git repos.
    _git_cache="$result"
    _git_cache_dir="$cwd"
    _git_cache_time="$now"

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

# source various helper scripts
_dotfiles_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$_dotfiles_root/tools/kuse/kuse.sh"
unset _dotfiles_root
