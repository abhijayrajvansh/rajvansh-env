# alias and shortcuts:- 
alias currUsername="echo Current user is: \$(whoami)"
alias root="cd /Users/\$(whoami)"
alias rr='kk && source ~/.zshrc'
# reload -> normal zshrc reload
alias hrr='root; rr'
# hrr -> hot reload



# zsh config
alias pip='pip3'
alias python='python3'
alias py='python'
alias kk='clear'    
alias la='ls -l'
alias app='python app.py'
alias oo='open .'
alias ff='fzf'
alias zz='cd ..'

# zsh configfunctions and Commandline:-
alias zshrc='code ~/.zshrc'

autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%b '

# PROMPT='%n@%m %1~ %#'
# Default ZSH PROMPT
setopt PROMPT_SUBST
PROMPT='%F{green}%*%f %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f$ '


# git version control
removeJunk () {
    rm .DS_Store
}

gpush () {
    removeJunk
    git status
    git add .
    git status
    git commit -m "$1"
    git push
}

alias push-zsh="cp /users/\$(whoami)/.zshrc /Users/\$(whoami)/Programming-Environment-2024/zsh; my-env; gpush 'updating zsh config'"

# author's Local Custom:-
alias download-cohort-assignment='desktop && git clone https://github.com/100xdevs-cohort-2/assignments.git'


# launching applications
alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

#directories
alias desktop="cd /Users/\$(whoami)/Desktop"
alias upwork="cd /Users/\$(whoami)/Upwork"
alias archive="cd /Users/\$(whoami)/Archive"
alias documents="cd /Users/\$(whoami)/Documents"
alias developer="cd /Users/\$(whoami)/Developer"
alias downloads="cd /Users/\$(whoami)/Downloads"
alias projects="cd /Users/\$(whoami)/Developer/projects"
alias movies="cd /Users/\$(whoami)/Movies"
alias linkedin="cd /Users/\$(whoami)/Linkedin"
alias my-env="cd /Users/\$(whoami)/Programming-Environment-2024"

# developer:-

alias concepts='cd /Users/\$(whoami)/Developer/software-engineering-concepts; code README.md'

main () {
    desktop
    prg main.js
}

#debug
deb () {
    node "$1".js
}

alias cohort="cd /Users/\$(whoami)/Developer/100xdev-cohort-2.0/"

# to hide and reveal desktop icons (mac machines)
alias showdesktop='defaults write com.apple.finder CreateDesktop true; killall Finder'
alias hidedesktop='defaults write com.apple.finder CreateDesktop false; killall Finder'  

# Node Version Manager:-
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  


prg () {
    touch $1
    code $1
}

# to create vite + react app
react-init () {
    npm create vite@latest ./
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #