parse_git_branch() {
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

userHost="\[\e[1;32m\]\u\[\e[m\]\[\e[1;32m\]@\[\e[m\]\[\e[1;32m\]\h\[\e[m\]"
points=":"
path="\[\e[1;34m\]\w\[\e[m\]"
rootUid="\\$"
git="\[\e[1;31m\]\$(parse_git_branch)\[\e[m\] "

PS1="$userHost$points$path$rootUid$git"
