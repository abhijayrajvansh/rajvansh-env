# username and root access
alias currUsername="echo New Session Started, Current User is: abhijayrajvansh"
alias root="cd /Users/abhijayrajvansh"

# reload: normal zshrc refresh reload
alias reload='kk && source ~/.zshrc'

# hrr -> hot reload: refresh and goto root
alias hrr='root; reload'

# compiler shortcuts config
alias python='python3'
alias py='python'
alias kk='clear' 

# shows list by date modified   
alias la='ls -l -G'
alias app='python app.py'
alias oo='open .'
alias ff='fzf'
alias zz='cd ..'
alias zzz='cd ../..'

# Github Repository
alias readme-format='cd /Users/abhijayrajvansh/Github/documentation-format; cat README.md'

# git version control
removeJunk () {
    rm .DS_Store
}

# github aliases
alias gs='git status'
alias ga='git add .'
alias gp='git push'
alias gc='git clone'
alias gp='git push'

gpush () {
    removeJunk
    git add .
    git status
    git commit -m "$1"
    git push
}

# zsh configfunctions and Commandline
alias zshrc='code ~/.zshrc'

# updating .zshrc file in git remote repo
alias pz="cp /users/abhijayrajvansh/.zshrc /Users/abhijayrajvansh/Programming-Environment-2024/zsh; my-env; gpush 'update: optimized zsh config'"

autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%b '
# {PROMPT='%n@%m %1~ %#}Default ZSH PROMPT

setopt PROMPT_SUBST
PROMPT='%F{green}%*%f %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f$ '

# abhijayrajvansh's Local dir
alias awwwards='cd /Users/abhijayrajvansh/Developer/projects/awwwards-library'


# launching applications
alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

#directories
alias desktop="cd /Users/abhijayrajvansh/Desktop"
alias archives="cd /Users/abhijayrajvansh/Archives"
alias documents="cd /Users/abhijayrajvansh/Documents"
alias downloads="cd /Users/abhijayrajvansh/Downloads"
alias movies="cd /Users/abhijayrajvansh/Movies"
alias pics='cd /Users/abhijayrajvansh/Pictures'

# productivity
alias my-env="cd /Users/abhijayrajvansh/Programming-Environment-2024"
alias dev="cd /Users/abhijayrajvansh/Developer"
alias github='cd /Users/abhijayrajvansh/Github'
alias projects="cd /Users/abhijayrajvansh/Developer/projects"
alias upwork="cd /Users/abhijayrajvansh/Upwork"

# linkedin 
alias linkedin="cd /Users/abhijayrajvansh/Linkedin"
alias certificates='cd /Users/abhijayrajvansh/Linkedin/certificates'

# local projects
alias snake='cd /Users/abhijayrajvansh/Developer/projects/snake-game-vanillaJS'


# developer
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

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  

clear; currUsername;