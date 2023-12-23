# alias and shortcuts:- 
alias root='cd /Users/abhijayrajvansh'
alias rr='root; reload'
# rr -> root reload

alias pip='pip3'
alias python='python3'
alias py='python'
alias kk='clear'    
alias la='ls -l'
alias app='python app.py'
alias oo='open .'
alias reload='kk && zsh'
alias ff='fzf'
alias zz='cd ..'

# zsh configfunctions and Commandline:-
alias zshrc='code /Users/abhijayrajvansh/.zshrc'

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

alias push-zsh="cp /users/abhijayrajvansh/.zshrc /Users/abhijayrajvansh/Programming-Environment-2024/zsh; my-env; gpush 'updating zsh config'"

# author's Local Custom:-
alias download-cohort-assignment='desktop && git clone https://github.com/100xdevs-cohort-2/assignments.git'


# launching applications
alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

#directories
alias desktop='cd /Users/abhijayrajvansh/Desktop'
alias upwork='cd /Users/abhijayrajvansh/Upwork'
alias archive='cd /Users/abhijayrajvansh/Archive'
alias documents='cd /Users/abhijayrajvansh/Documents'
alias developer='cd /Users/abhijayrajvansh/Developer'
alias downloads='cd /Users/abhijayrajvansh/Downloads'
alias projects='cd /Users/abhijayrajvansh/Developer/projects'
alias movies='cd /Users/abhijayrajvansh/Movies'
alias linkedin='cd /Users/abhijayrajvansh/Linkedin'
alias my-env='cd /Users/abhijayrajvansh/Programming-Environment-2024'

# developer:-

alias concepts='cd /Users/abhijayrajvansh/Developer/software-engineering-concepts; code README.md'

main () {
    desktop
    prg main.js
}

#debug
deb () {
    node "$1".js
}

alias cohort='cd /Users/abhijayrajvansh/Developer/100xdev-cohort-2.0/'

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