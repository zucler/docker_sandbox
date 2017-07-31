# .bash_profile
case $- in *i*) . ~/.bashrc;; esac

# Almost unlimited history size
HISTFILESIZE=1000000

# Make ls use colours
export PS1="\\[\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h:\[\033[33;1m\]\w\[\033[m\]\$ "

# Support 256 colours
export TERM=xterm-256color

# Command shortcuts
alias ls='ls -lF --color=auto'
alias ll='ls -lFa --color=auto'
alias grep='grep --color="always"'
alias ack='ack --color'
alias less='less -r'
