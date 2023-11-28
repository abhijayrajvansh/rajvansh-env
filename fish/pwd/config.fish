set fish_greeting

if status is-interactive
    #   here goes startup message
    alias getcontrol='fish /Users/abhijayrajvansh/.config/fish/greetme.fish'
    
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

    #Development
    alias launch='npm i && npm start'
    # Node Version Manager

    # export NVM_DIR="$HOME/.nvm"
    # [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    # [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion



    
    # Fish functions and Commandline:-
    function fish_prompt
        set -l prompt_symbol '$: '
        echo (set_color --bold green)'abhijay@macbook'(set_color --italic green)(prompt_pwd) \
        (set_color --bold white)$prompt_symbol(set_color normal)
    end

    alias fish-c='code /Users/abhijayrajvansh/.config/fish/config.fish'
    
    function push-fish
        cp -r /Users/abhijayrajvansh/.config/fish/ /Users/abhijayrajvansh/Desktop/Programming-Environment-2024//fish/
        

    # Startup commands
    #write 'dk' for jumping to desktop
end