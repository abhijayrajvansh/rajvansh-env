# Custom Functions:- version update and shortcuts:-
alias root='cd /Users/abhijayrajvansh'
alias g++='g++-12'
alias gcc='gcc-12'
alias pip='pip3'
alias python='python3'
alias py='python'
alias kk='clear'    
alias la='ls -l'
alias app='python app.py'
alias oo='open .'

# Author's Local Custom
alias download-cohort-assignment='dk && git clone https://github.com/100xdevs-cohort-2/assignments.git'

alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

#Custom code for mac machines
alias showdesktop='defaults write com.apple.finder CreateDesktop true;killall Finder'
alias hidedesktop='defaults write com.apple.finder CreateDesktop false;killall Finder'  

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  

#Development
alias cohort='cd /Users/abhijayrajvansh/Desktop/100xdev-cohort-2.0/'


#directories
alias desktop='cd /Users/abhijayrajvansh/Desktop'
alias documents='cd /Users/abhijayrajvansh/Documents'
alias development='cd /Users/abhijayrajvansh/Development'
alias movies='cd /Users/abhijayrajvansh/Movies'
alias linkedin='cd /Users/abhijayrajvansh/Linkedin'
alias my-env='cd /Users/abhijayrajvansh/Programming-Environment-2024'


# Zsh configfunctions and Commandline:-
alias zshrc='code /Users/abhijayrajvansh/.zshrc'


gitpush () {
    git add .
    git commit -m "$1"
    git push
}

push-zsh () {
    #copying local zsh into remote repo
    cp /users/abhijayrajvansh/.zshrc /Users/abhijayrajvansh/Programming-Environment-2024/zsh 
    my-env
    gitpush 'updating zsh config'
}