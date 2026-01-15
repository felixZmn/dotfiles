git_prompt_bold() {
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
        printf "\001\033[0m\002 "
    }'
}

userHost="\[\e[1;32m\]\u\[\e[m\]\[\e[1;32m\]@\[\e[m\]\[\e[1;32m\]\h\[\e[m\]"
path="\[\e[1;34m\]\w\[\e[m\]"
PS1="$userHost:$path\$(git_prompt_bold)\\$ "