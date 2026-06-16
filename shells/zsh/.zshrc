# ============================================================================
# Git-Aware Prompt
# ============================================================================
# Displays branch, commit status (ahead/behind), staged files, and modifications
# Uses git status --porcelain=v2 for efficiency
# Adapted for zsh syntax (no need for ANSI escape sequence delimiters like bash)

git_info() {
    git status --porcelain=v2 --branch 2>/dev/null | awk '
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
        printf "%s[1;33m [%s%s[0m", "\033", b, "\033"
        
        # Ahead: Bold Green (1;32)
        if(a>0) printf " %s[1;32m↑%d%s[0m", "\033", a, "\033"
        
        # Behind: Bold Red (1;31)
        if(d<0) printf " %s[1;31m↓%d%s[0m", "\033", d*-1, "\033"
        
        # Close Bracket: Bold Yellow (1;33)
        printf "%s[1;33m]%s[0m", "\033", "\033"
        
        # Staged: Bold Green (1;32)
        if(s) printf " %s[1;32m+%d%s[0m", "\033", s, "\033"
        
        # Dirty (Any unstaged change): Bold Red (1;31)
        if(w) printf " %s[1;31m~%s[0m", "\033", "\033"
        
        # Space before prompt
        printf " "
    }'
}

# zsh prompt syntax: %n@%m:%~ for user@host:path
PROMPT='%B%F{green}%n%f@%F{green}%m%f%b:%B%F{blue}%~%b$(git_info)%# '
