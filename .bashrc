parse_git_branch() {
    git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

userHost="\e[1;32m\u@\h\e[m"
points="\e[0;30m:\e[m"
path="\e[1;34m\w\e[m"
rootUid="\e[0;30m\$\e[m"
git="\e[1;31m\$(parse_git_branch)\e[m"

PS1="$userHost$points$path$rootUid$git"
