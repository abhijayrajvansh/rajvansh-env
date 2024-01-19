# alias and shortcuts:- 
alias currUsername="echo New Session Started, Current User is: abhijayrajvansh"
alias root="cd /Users/abhijayrajvansh"

# reload -> normal zshrc refresh reload
alias rr='kk && source ~/.zshrc'

# hrr -> hot reload: refresh and goto root
alias hrr='root; rr'

# zsh config
alias python='python3'
alias py='python'
alias kk='clear' 

# shows list by date modified   
alias la='ls -al -G'
alias app='python app.py'
alias oo='open .'
alias ff='fzf'
alias zz='cd ..'
alias zzz='cd ../..'

# zsh configfunctions and Commandline:-
alias zshrc='code ~/.zshrc'

autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%b '
# {PROMPT='%n@%m %1~ %#}Default ZSH PROMPT

setopt PROMPT_SUBST
PROMPT='%F{green}%*%f %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f$ '


# git version control
removeJunk () {
    rm .DS_Store
}

# Github Custom

alias gs='git status'

gpush () {
    removeJunk
    echo "Log all updates before, git push!"
    git add .
    git status
    git commit -m "$1"
    git push
}

alias push-zsh="cp /users/abhijayrajvansh/.zshrc /Users/abhijayrajvansh/Programming-Environment-2024/zsh; my-env; gpush 'updating zsh config'"

# author's Local Custom:-
alias download-cohort-assignment='desktop && git clone https://github.com/100xdevs-cohort-2/assignments.git'
alias awwwards='cd /Users/abhijayrajvansh/Developer/projects/awwwards-library'


# launching applications
alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

#directories
alias desktop="cd /Users/abhijayrajvansh/Desktop"
alias upwork="cd /Users/abhijayrajvansh/Upwork"
alias archive="cd /Users/abhijayrajvansh/Archive"
alias documents="cd /Users/abhijayrajvansh/Documents"
alias developer="cd /Users/abhijayrajvansh/Developer"
alias downloads="cd /Users/abhijayrajvansh/Downloads"
alias movies="cd /Users/abhijayrajvansh/Movies"
alias linkedin="cd /Users/abhijayrajvansh/Linkedin"
alias my-env="cd /Users/abhijayrajvansh/Programming-Environment-2024"

# developer targeted repository:
alias react='cd /Users/abhijayrajvansh/Developer/react.js/'
alias css='cd /Users/abhijayrajvansh/Developer/tailwindCSS'
alias projects="cd /Users/abhijayrajvansh/Developer/projects"
alias typescript='cd /Users/abhijayrajvansh/Developer/typescript'


# developer:-
alias concepts="cd /Users/abhijayrajvansh/Developer/software-engineering-concepts; code README.md"

main () {
    desktop
    prg main.js
}

#debug
deb () {
    node "$1".js
}

alias cohort="cd /Users/abhijayrajvansh/Developer/100xdev-cohort-2.0/"

# to hide and reveal desktop icons (mac machines)
alias showdesktop='defaults write com.apple.finder CreateDesktop true; killall Finder'
alias hidedesktop='defaults write com.apple.finder CreateDesktop false; killall Finder'  

# Node Version Manager:-
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  

clear; currUsername;