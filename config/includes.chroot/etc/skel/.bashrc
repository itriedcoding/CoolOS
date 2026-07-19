# CoolOS Bash Configuration

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
HISTTIMEFORMAT="%F %T  "

# Check window size after each command
shopt -s checkwinsize

# Make less more friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# Set variable identifying the chroot you work in
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Set a fancy prompt
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@CoolOS\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Enable color support of ls
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'

# Alias commands
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'

# Custom aliases
alias update='sudo apt update && sudo apt upgrade -y'
alias install='sudo apt install -y'
alias remove='sudo apt remove -y'
alias search='apt search'
alias clean='sudo apt clean && sudo apt autoremove -y'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log'
alias gd='git diff'
alias gb='git branch'
alias checkout='git checkout'

# Docker aliases
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlogs='docker logs -f'

# System aliases
alias reboot='sudo reboot'
alias shutdown='sudo shutdown -h now'
alias services='systemctl list-units --type=service'
alias ports='netstat -tuln'

# Function to extract archives
extract() {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)   tar xjf $1     ;;
            *.tar.gz)    tar xzf $1     ;;
            *.bz2)       bunzip2 $1     ;;
            *.rar)       unrar x $1     ;;
            *.gz)        gunzip $1      ;;
            *.tar)       tar xf $1      ;;
            *.tbz2)      tar xjf $1     ;;
            *.tgz)       tar xzf $1     ;;
            *.zip)       unzip $1       ;;
            *.Z)         uncompress $1  ;;
            *.7z)        7z x $1        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Function to create and enter directory
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Function to find files
ff() {
    find . -name "$1" 2>/dev/null
}

# Function to find directories
fd() {
    find . -type d -name "$1" 2>/dev/null
}

# Function to show disk usage
du() {
    command du -h "$@"
}

# Function to show memory usage
free() {
    command free -h
}

# Function to show processes
ps() {
    command ps auxf
}

# Enable programmable completion features
if ! shopt -oq posix; then
    if [ -f /usr/share/bash-completion/bash_completion ]; then
        . /usr/share/bash-completion/bash_completion
    elif [ -f /etc/bash_completion ]; then
        . /etc/bash_completion
    fi
fi

# Source local bashrc if exists
[ -f ~/.bashrc.local ] && . ~/.bashrc.local

# Welcome message
echo ""
echo "  ╔══════════════════════════════════════════╗"
echo "  ║           Welcome to CoolOS!              ║"
echo "  ║        A Lightweight Linux Distro         ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""
echo "  Type 'help' for available commands"
echo "  Type 'update' to update system"
echo ""
