# CoolOS Bash Configuration

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000

# Check window size after each command
shopt -s checkwinsize

# Set fancy prompt
PS1='\[\033[01;32m\]\u@CoolOS\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Color support
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'

# Safety aliases
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# System aliases
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install -y'
alias search='apt search'

# Extract archives
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1   ;;
            *.tar.gz)    tar xzf $1   ;;
            *.bz2)       bunzip2 $1   ;;
            *.rar)       unrar x $1   ;;
            *.gz)        gunzip $1    ;;
            *.tar)       tar xf $1    ;;
            *.zip)       unzip $1     ;;
            *.7z)        7z x $1      ;;
            *)           echo "'$1' cannot be extracted" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Welcome message
echo ""
echo "  Welcome to CoolOS!"
echo "  Type 'update' to update system"
echo ""
