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
alias dk='cd /Users/abhijayrajvansh/Desktop'
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



# Zsh configfunctions and Commandline:-
alias zshrc='code /Users/abhijayrajvansh/.zshrc'


update-zsh () {
    cp -r /Users/abhijayrajvansh/.config/.zshrc/ /Users/abhijayrajvansh/Desktop/Programming-Environment-2024/zsh/
    /Users/abhijayrajvansh/Desktop/Programming-Environment-2024
    git add zsh
    git commit -m "udpating .zshrc"
    git push
}

push-zsh () {
    root
    cp -r /User
}

gitpush () {
    git add .
    git commit -m "updating and debugging repository"
    git push
}