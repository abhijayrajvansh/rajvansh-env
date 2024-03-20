# username and root access
alias newSessionNotification="echo New Session Started, Current User is: abhijayrajvansh"
alias root="cd /Users/abhijayrajvansh/"

# reload: normal zshrc refresh reload
alias reload='clear && source ~/.zshrc'

# zsh-autosuggestions
alias include-autosuggestions='source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh'

# hrr -> hot reload: fetches last updated zshrc and goes to root
alias hrr='reload; root;'

# navigation   
alias la='ls -l -G'
alias kk='clear' 
alias oo='open .'
alias zz='cd ..'
alias zzz='cd ../..'

# python specifc shortcuts config
alias python='python3'
alias app='python app.py'
alias py='python'
alias pip='pip3'

# homebrew aliases
alias bi='brew install'
alias bui='brew uninstall'

# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" 

# Node package manager
alias ni='npm install'
alias ndev='npm run dev'

# Perfomant NPM
alias pp='pnpm'
alias ppi='pnpm install'
alias ppa='pnpm add'
alias ppd='ppi; pnpm run dev'
alias pps='ppi; pnpm run start'

alias cna='pp create next-app'

export PNPM_HOME="/Users/abhijayrajvansh/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# Github Repository
alias readme-format='code ~/Github/README.md'
alias gitignore-format='code ~/Github/.gitignore'

# github aliases
mygithub='https://github.com/abhijayrajvansh/'

alias gs='git status'
alias ga='git add .'

gcm () {
  git commit -m "$1"
}

alias gpl='git pull'
alias gc='git clone'

gpush () {
    rm .DS_Store
    git add .
    git status
    git commit -m $1  
    git push
}

#  git push with commit and default value
gp () {
  if [ -z "$1" ]; then
    gpush 'update: audit push from local env'
  else
    gpush $1
  fi
}

# zsh configfunctions and Commandline
alias zshrc='code ~/.zshrc'

# updating .zshrc file and code snippets in git remote repo
alias cp-lzsh-rzsh='cp /Users/abhijayrajvansh/.zshrc /Users/abhijayrajvansh/Programming-Environment-2024/zsh'
alias cp-rzsh-lzsh='cp /Users/abhijayrajvansh/Programming-Environment-2024/zsh/.zshrc /Users/abhijayrajvansh/'
alias cp-lsnpt-rsnpt='cp -r /Users/abhijayrajvansh/Library/Application\ Support/Code/User/snippets /Users/abhijayrajvansh/Programming-Environment-2024'
alias cp-rsnpt-lsnpt='cp -r /Users/abhijayrajvansh/Programming-Environment-2024/snippets /Users/abhijayrajvansh/Library/Application\ Support/Code/User '

alias pz="cp-lzsh-rzsh; cp-lsnpt-rsnpt; myenv; gp 'update: optimized env and audit fix'"
alias updatenv='myenv; git pull; cp-rzsh-lzsh; cp-rsnpt-lsnpt;'

autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%b'
# {PROMPT='%n@%m %1~ %#}Default ZSH PROMPT

setopt PROMPT_SUBST
PROMPT='%F{green}%*%f: %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f $ '

# launching applications
alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# default directories
alias desktop="cd /Users/abhijayrajvansh/Desktop"
alias documents="cd /Users/abhijayrajvansh/Documents"
alias downloads="cd /Users/abhijayrajvansh/Downloads"
alias movies="cd /Users/abhijayrajvansh/Movies"
alias pictures='cd /Users/abhijayrajvansh/Pictures'

# productivity
alias myenv="cd /Users/abhijayrajvansh/programming-environment-2024"
alias archives="cd /Users/abhijayrajvansh/Archives"
alias github='cd /Users/abhijayrajvansh/Github'
alias upwork="cd /Users/abhijayrajvansh/Upwork"
alias x='cd /Users/abhijayrajvansh/X'

# workspace and development related directories, aliases and functions

#mongodb
alias start-mongodb='brew services start mongodb-community@7.0'
alias stop-mongodb='brew services stop mongodb-community@7.0'

# creating files and launching them in vscode
prg() {
  for arg in "$@"; do
    echo "creating: $arg"
    touch $arg
    code $arg
  done
}

alias developer="cd /Users/abhijayrajvansh/Developer"
alias snippets='cd /Users/abhijayrajvansh/Library/Application\ Support/Code/User/snippets'
alias projects="cd /Users/abhijayrajvansh/Developer/projects"
alias concepts="cd /Users/abhijayrajvansh/Developer/software-engineering-concepts; code README.md"
alias dcp='cd /Users/abhijayrajvansh/Developer/dev-concepts-practice'


# on goining projects
alias portfolio='cd /Users/abhijayrajvansh/Desktop/portfolio.js'
alias backend='cd /Users/abhijayrajvansh/Desktop/gettingstartedwithbackend'
alias netflix='cd /Users/abhijayrajvansh/Desktop/netflix-clone-next.js'
alias twitter='cd /Users/abhijayrajvansh/Desktop/twitter-clone-next.js'

# linkedin stuff
alias linkedin="cd /Users/abhijayrajvansh/Linkedin"
alias certificates='cd /Users/abhijayrajvansh/Linkedin/certificates'

# to hide and reveal desktop icons (mac machines)
alias showdesktop='defaults write com.apple.finder CreateDesktop true; killall Finder'
alias hidedesktop='defaults write com.apple.finder CreateDesktop false; killall Finder'   

# more aliases:
alias bucketlist='cd /Users/abhijayrajvansh/Archives/bucketlist'
alias dev='developer'
alias desk='desktop'
alias docs='documents'
alias pics='pictures'

# END OF THE DOCUMENT!!!
