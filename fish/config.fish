set fish_greeting

if status is-interactive
    clear
    #   here goes startup message
    alias getcontrol='fish /Users/abhijayrajvansh/.config/fish/greetme.fish'
    
    # Custom Functions:- version update and shortcuts
    # Terminal Custom: -
    alias remove-executables='rm *.out'
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
    alias notes='cd /Users/abhijayrajvansh/Desktop/files && prg notes.txt'
    alias nv ='nvim'
    alias desktop='cd /Users/abhijayrajvansh/Desktop'
    alias fish-c='code /Users/abhijayrajvansh/.config/fish/config.fish'
    alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
    export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
    
    alias showdesktop='defaults write com.apple.finder CreateDesktop true;killall Finder'
    alias hidedesktop='defaults write com.apple.finder CreateDesktop false;killall Finder'  

    #development
    alias launch='npm i && npm start'
    
    alias git-push-vscode-snippets='cp -r /Users/abhijayrajvansh/Library/Application\ Support/Code/user/snippets/ /Users/abhijayrajvansh/Desktop/programming-environment-2023/vscode && cd /Users/abhijayrajvansh/Desktop/programming-environment-2023/vscode && git-push "Updating User Snippets From VScode"'
    
    function push-templates
        git-push-vscode-snippets
        echo
        echo "Successfully Completed ✅, lesssgoo 🚀"
    end

    alias project-time='cd /Users/abhijayrajvansh/Desktop/development/projects/Project-TIME'
    alias wb='python /Users/abhijayrajvansh/Desktop/development/projects/Launch-Websites/wb.py'
    alias url-remaker='cd /Users/abhijayrajvansh/Personal-Stuff/url-remaker'
    alias rajvansh-os='cd /Users/abhijayrajvansh/Desktop/development/projects/Rajvansh-os'
    
    function naruto  
        cd "/Users/abhijayrajvansh/Desktop/development/projects/Naruto-Bot" 
        app $argv
    end

    alias mygithub='cd /Users/abhijayrajvansh/Desktop/development/projects/Fire-Websites && py mygithub.py'


    # CommandLine Debug during contests:- Compile, Debug && Timed: C++
    function cpp # ABHIJAY_DEBUG FILE_NAME.cpp
        echo "Compiling" $argv" with G++17..."
        sleep 1
        g++ -std=c++17 $argv -o a.out && ./a.out
    end

    function deb # ABHIJAY_DEBUG FILE_NAME.cpp
        echo "[ABHIJAY_DEBUG MODE] Compiling" $argv.cpp" with G++17..."
        # sleep 1
        g++ -std=c++17 -DABHIJAY_DEBUG $argv.cpp
        ./a.out
    end
    
    # alias deb-main='echo "[ABHIJAY_DEBUG MODE] Compiling main.cpp with G++17..." && g++ -DABHIJAY_DEBUG main.cpp -o main && ./main'


    # SRM and Academics:

    alias srm='cd /Users/abhijayrajvansh/Desktop/6th-Sem'
    alias academics='srm'
    alias tt='cd /Users/abhijayrajvansh/Desktop/6th-SEM && oo tt.jpeg'

    #Programming environment:
    alias programming-environment='desktop && cd programming-environment-2023'
    alias template='cd /Users/abhijayrajvansh/Desktop/programming-environment-2023/Templates'
    alias abhijayrajvansh.cpp='template && prg abhijayrajvansh.cpp'



    # Fish
    function reload
        echo "[Previous Direcotry:]"
        pwd
        fish
    end

    # function fish_prompt
    #     set -l prompt_symbol '$: '
    #     echo (set_color --bold green)'abhijay@macbook:'(set_color --bold blue)(prompt_pwd) \
    #     (set_color --bold yellow)$prompt_symbol(set_color normal) 
    # end

    # function fish_prompt
    #     set -l prompt_symbol '$:'
    #     echo (set_color --bold green)'abhijayrajvansh@macbook'(set_color --bold blue)(prompt_pwd) \
    #     (set_color --bold yellow)$prompt_symbol(set_color normal)
    # end

    function fish_prompt
        set -l prompt_symbol '$: '
        echo (set_color --bold green)'abhijay@macbook'(set_color --italic green)(prompt_pwd) \
        (set_color --bold white)$prompt_symbol(set_color normal)
    end

    function clean
        rm $argv
        touch $argv
    end

    function clear-dir
        rm -r $argv
        mkdir $argv
    end

    function prg
        # code ./contest-library
        touch $argv      
        code $argv
    end

    # github
    alias push='git-push "updating files & debugging"'

    function git-push
        rm .DS_Store
        rm *.out
        rm debug_error.txt
        git add .
        git commit -m "$argv"
        git push
    end

    function push-fish
        echo "Copying config.fish to github fish repo..."
        echo
        cp -r /Users/abhijayrajvansh/.config/fish /Users/abhijayrajvansh/desktop/programming-environment-2023
        programming-environment
        git-push "Updating Fish With Programming Environment 💙"    
        echo
        echo "Successfully Completed ✅"
    end

    desktop
end



# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
