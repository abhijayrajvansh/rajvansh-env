# Custom Functions:- version update and shortcuts:-
alias root='cd /Users/abhijayrajvansh'
alias g++='g++-12'
alias gcc='gcc-12'
alias pip='pip3'
alias python='python3'
alias py='python'
alias kk='clear'
alias kkk='clear'
alias lkk='clear'
alias la='ls -l'
alias app='python app.py'
alias oo='open .'

alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

#Custom code for mac machines
alias showdesktop='defaults write com.apple.finder CreateDesktop true;killall Finder'
alias hidedesktop='defaults write com.apple.finder CreateDesktop false;killall Finder'  

# Node Version Manager
# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#Development
alias launch='npm i && npm start'



#direcotry
alias dk='cd /Users/abhijayrajvansh/Desktop'
alias my-env='cd /Users/abhijayrajvansh/Desktop/Programming-Environment-2024'


# Zsh configfunctions and Commandline:-
alias zshrc='code /Users/abhijayrajvansh/.zshrc'


gitpush () {
    git add .
    git commit -m "$1"
    git push
}

push-zsh () {
    #copying local zsh into remote repo
    cp /users/abhijayrajvansh/.zshrc /Users/abhijayrajvansh/Desktop/Programming-Environment-2024/zsh 
    my-env
    gitpush
}

