# username and root access
alias newSessionNotification="echo New Session Started, Current User is: abhijayrajvansh"
alias root="cd /Users/abhijayrajvansh/"

# reload: normal zshrc refresh reload
alias reload='clear && source ~/.zshrc'

# zsh-autosuggestions
alias import-autosuggestions='source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh'
import-autosuggestions

# hrr -> hot reload: fetches last updated zshrc and goes to root
alias hrr='reload; root;'

# navigation   
alias la='ls -l -G'
alias ll='ls -al -G'
alias kk='clear' 
alias oo='open .'
alias zz='cd ..'
alias xx='exit'

# quick commands
alias python='python3'
alias app='python app.py'
alias py='python'
alias pip='pip3'

# C/C++ GCC G++ Compliers

deb () {
  g++-12 -D ABHIJAY_DEBUG $1.cpp
  ./a.out
}

run () {
  g++-12 $1.cpp
  ./a.out
}

alias gg='deb main'

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

# Git related aliases
alias readme-format='code ~/Github/README.md'
alias gitignore-format='code ~/Github/.gitignore'

mygithub='https://github.com/abhijayrajvansh/'

alias gs='git status'
alias ga='git add . ; gs;'
alias gd='git diff'
alias gpl='git pull'
alias gcl='git clone'

gc () {
  git commit -m "$1"
}

gpush () {
    rm .DS_Store
    git add .
    git status
    git commit -m $1 

	if [ -z "$2" ]; then
		git push origin main
	else
		git push origin $2
	fi
}

#  git push with commit and default value
gp () {
  if [ -z "$1" ]; then
    gpush 'update: audit fixes and changes'
  else
    gpush $1 $2
  fi
}

# zsh configfunctions and Commandline
alias zshrc='code ~/.zshrc'

# updating .zshrc file and code snippets in git remote repo
alias cp-lzsh-rzsh='cp /Users/abhijayrajvansh/.zshrc /Users/abhijayrajvansh/Programming-Environment-2024/zsh'
alias cp-rzsh-lzsh='cp /Users/abhijayrajvansh/Programming-Environment-2024/zsh/.zshrc /Users/abhijayrajvansh/'

alias cp-lsnpt-rsnpt='cp -r /Users/abhijayrajvansh/Library/Application\ Support/Code/User/snippets /Users/abhijayrajvansh/Programming-Environment-2024'
alias cp-rsnpt-lsnpt='cp -r /Users/abhijayrajvansh/Programming-Environment-2024/snippets /Users/abhijayrajvansh/Library/Application\ Support/Code/User'

alias cp-lnvcf-rnvcf='cp -r ~/.config/nvim ~/programming-environment-2024/'
alias cp-rnvcf-lnvcf='cp -r ~/programming-environment-2024/nvim ~/.config/'

alias pz="cp-lzsh-rzsh; cp-lsnpt-rsnpt; cp-lnvcf-rnvcf; myenv; gp 'update: optimized env and audit fix'"
alias gz='myenv; git pull; cp-rzsh-lzsh; cp-rsnpt-lsnpt; cp-rnvcf-lnvcf;'

# {PROMPT='%n@%m %1~ %#}Default ZSH PROMPT
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%b'

setopt PROMPT_SUBST
PROMPT='%F{green}[%*]%f: %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f $ '

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


# neo vim
alias nv='nvim'
alias nvconfig='nv ~/.config/nvim/init.vim'

# launching files and launching them in vscode
prg() {
  for arg in "$@"; do
    echo "launching: $arg"
    touch $arg
    code $arg
  done
}

# VSCode settings:
alias code-setting='code /Users/abhijayrajvansh/Library/Application\ Support/Code/User/settings.json'

# on goining projects
alias portfolio='cd /Users/abhijayrajvansh/Desktop/portfolio.js'
alias backend='cd /Users/abhijayrajvansh/Desktop/server-side-programming'
alias netflix='cd /Users/abhijayrajvansh/Desktop/netflix-clone-next.js'
alias meetup='cd /Users/abhijayrajvansh/Desktop/meetup'
alias checklist='desk && cd checklist'
alias twt='desk; cd twitter-clone-next.js'

# software dir
alias developer="cd /Users/abhijayrajvansh/Developer"
alias snippets='cd /Users/abhijayrajvansh/Library/Application\ Support/Code/User/snippets'
alias concepts="cd /Users/abhijayrajvansh/Developer/software-engineering-concepts; code README.md"
alias dcp='cd /Users/abhijayrajvansh/Developer/dev-concepts-practice'

alias projects="echo '\n✅ projects are shifted to notion.\n'"

# linkedin portfolio stuff
alias linkedin="cd /Users/abhijayrajvansh/Linkedin"
alias certificates='cd /Users/abhijayrajvansh/Linkedin/certificates'

# to hide and reveal desktop icons (mac machines)
alias showdesktop='defaults write com.apple.finder CreateDesktop true; killall Finder'
alias hidedesktop='defaults write com.apple.finder CreateDesktop false; killall Finder'   

# more aliases:
alias apps='cd /Applications/'
alias dev='developer'
alias desk='desktop'
alias docs='documents'
alias pics='pictures'

# End of the document