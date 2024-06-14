# username and root access
alias newSessionNotification="echo New Session Started, Welcome Back Mr.Rajvansh"
alias root="cd /Users/abhijayrajvansh/"

# zsh-autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# {PROMPT='%n@%m %1~ %#}Default ZSH PROMPT
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%F{cyan}git:(%f%F{red}%b%f%F{cyan})%f'

setopt PROMPT_SUBST
PROMPT='%F{green}[%*]%f: %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f %F{yellow}$%f '

# reload: normal zshrc refresh reload
alias reload='root && clear && source ~/.zshrc'
alias rr='reload'

# to hide and reveal desktop icons (mac machines)
alias showdesktop='defaults write com.apple.finder CreateDesktop true; killall Finder'
alias hidedesktop='defaults write com.apple.finder CreateDesktop false; killall Finder'  

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET='\033[0m'

alias greentick='echo -n ${GREEN}✔ ${RESET}'
alias redcross='echo -n ${RED}✘ ${RESET}'
  
# navigation   
alias la='ls -l -G'
alias ll='ls -al -G'
alias l='ll'
alias kk='clear' 
alias oo='open .'
alias zz='cd ..'
alias xx='exit'

# C/C++ GCC G++ Compliers
deb () {
  g++-12 -D ABHIJAY_DEBUG $1.cpp
  ./a.out
}

run () {
  g++-12 $1.cpp
  ./a.out
}

# python related aliases
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

# Perfomant Node Package Manager or PNPM
alias pp='pnpm'
alias ppi='pnpm install'
alias ppa='pnpm add'
alias ppd='ppi; pnpm run dev'
alias pps='ppi; pnpm run start'

export PNPM_HOME="/Users/abhijayrajvansh/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Next.js related aliases
alias cna='pp create next-app'

# Git related aliases
mygithub='https://github.com/abhijayrajvansh/'

alias readme-format='code ~/Github/README.md'
alias gitignore-format='code ~/Github/.gitignore'
alias gs='git status'
alias ga='git add . ; gs;'
alias gd='git diff'
alias gpl='git pull'
alias gcl='git clone'

gpush () {
    rm .DS_Store
    git add .
    git status
    echo "\nUsing Commit Message: ${GREEN}$1${RESET}\n"
    git commit -m $1 

	if [ -z "$2" ]; then
    echo "\nPushing to branch: ${RED}main${RESET}\n"
		git push origin main
	else
    echo "\nPushing to branch: ${RED}$2${RESET}\n"
		git push origin $2
	fi
}

# git global default values:
default_commit_msg="wagmi: fixed bugs & improvements"
default_push_branch="main"

gc () {
  echo -n "Enter Commit (D- $default_commit_msg): "
  read commit_msg

  if [ -z "$commit_msg" ]; then
    commit_msg="$default_commit_msg"
  fi

  # git commands:
  git add .
  git status
  git commit -m "$commit_msg"
}

gp () {
  echo -n "Enter Commit (D- $default_commit_msg): "
  read commit_msg

  echo -n "Enter Branch (D- $default_push_branch): "
  read push_branch

  if [ -z "$commit_msg" ]; then
    commit_msg="$default_commit_msg"
  fi

  if [ -z "$push_branch" ]; then
    push_branch="$default_push_branch"
  fi

  echo ""
  echo -e "Using git commit message: ${GREEN}$commit_msg${RESET}"
  echo "Using git push branch: ${RED}$push_branch${RESET}"
  echo ""

  # git commands:
  git add .
  git status
  git commit -m "$commit_msg"
  git push origin "$push_branch"
}

# zsh configfunctions and Commandline:
alias zshrc='code ~/.zshrc; echo launching: zsh config'

# updating .zshrc file and code snippets in git remote repo:
alias cp-lzsh-rzsh='cp /Users/abhijayrajvansh/.zshrc /Users/abhijayrajvansh/Programming-Environment-2024/zsh'
alias cp-rzsh-lzsh='cp /Users/abhijayrajvansh/Programming-Environment-2024/zsh/.zshrc /Users/abhijayrajvansh/'

alias cp-lcodesetting-rcodesetting='cp -r /Users/abhijayrajvansh/Library/Application\ Support/Code/User/settings.json /Users/abhijayrajvansh/Programming-Environment-2024/vscode/'
alias cp-rcodesetting-lcodesetting='cp -r /Users/abhijayrajvansh/Programming-Environment-2024/vscode/settings.json /Users/abhijayrajvansh/Library/Application\ Support/Code/User/'

alias cp-lcodesnippets-rcodesnippets='cp -r /Users/abhijayrajvansh/Library/Application\ Support/Code/User/snippets /Users/abhijayrajvansh/Programming-Environment-2024/vscode/'
alias cp-rcodesnippets-lcodesnippets='cp -r /Users/abhijayrajvansh/Programming-Environment-2024/vscode/snippets /Users/abhijayrajvansh/Library/Application\ Support/Code/User/'

alias cp-lnvcf-rnvcf='cp -r ~/.config/nvim ~/programming-environment-2024/'
alias cp-rnvcf-lnvcf='cp -r ~/programming-environment-2024/nvim ~/.config/'

copy_localenv_to_remoteenv () {
  echo "Copying following configurations to remote environment:\n";
  greentick; echo "Copied rajvansh-cli and zsh config.";  cp-lzsh-rzsh;
  greentick; echo "Copied settings.json & snippets."; cp-lcodesetting-rcodesetting; cp-lcodesnippets-rcodesnippets;
  greentick; echo "Copied neovim config."; cp-lnvcf-rnvcf;
  echo
}

update_dev_configurations () {
  echo "Updating remote configurations to local environment:\n";
  greentick; echo "Updated rajvansh-cli and zsh config.";  cp-rzsh-lzsh;
  greentick; echo "Updated settings.json & snippets."; cp-rcodesetting-lcodesetting; cp-rcodesnippets-lcodesnippets;
  greentick; echo "Updated neovim config."; cp-rnvcf-lnvcf;
  echo
}

pz () {
  cd /Users/abhijayrajvansh/programming-environment-2024
  copy_localenv_to_remoteenv;
  gpush "update: audit push and improvements" main
}

gz () {
  cd /Users/abhijayrajvansh/programming-environment-2024
  git pull origin main;
  update_dev_configurations;
  echo "Reload .zshrc to reflect changes."
}

# neo vim
alias nv='nvim'
alias nvconfig='nv ~/.config/nvim/init.vim'

# launching applications
alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# creating files and launching in vscode
prg () {
  for arg in "$@"; do
    echo "launching: $arg"
    touch $arg
    code $arg
  done
}

# default directories
alias desktop="cd /Users/abhijayrajvansh/Desktop"
alias documents="cd /Users/abhijayrajvansh/Documents"
alias developer="cd /Users/abhijayrajvansh/Developer"
alias downloads="cd /Users/abhijayrajvansh/Downloads"
alias movies="cd /Users/abhijayrajvansh/Movies"

# quick directories
alias myenv="cd /Users/abhijayrajvansh/programming-environment-2024"
alias archives="cd /Users/abhijayrajvansh/Archives"
alias github='cd /Users/abhijayrajvansh/Github'
alias resume='cd ~/Documents/resume'

# VSCode settings:
alias code-setting='echo "launching: settings.json"; code /Users/abhijayrajvansh/Library/Application\ Support/Code/User/settings.json'
alias snippets='cd /Users/abhijayrajvansh/Library/Application\ Support/Code/User/snippets'

# software dir
alias concepts="cd /Users/abhijayrajvansh/Developer/software-engineering-concepts; code README.md"
alias dcp='cd /Users/abhijayrajvansh/Developer/dev-concepts-practice'
alias projects="greentick; echo 'projects are shifted to notion.'"

# linkedin portfolio stuff
alias linkedin="cd /Users/abhijayrajvansh/Linkedin"
alias certificates='cd /Users/abhijayrajvansh/Linkedin/certificates'

# quick aliases:
alias apps='cd /Applications/'
alias dev='developer'
alias desk='desktop'
alias docs='documents'
alias pics='cd /Users/abhijayrajvansh/Pictures/pics'

# postgres database
alias psql_docker_postgres='psql postgres://abhijay:rajvansh@localhost:5432/postgres'

# on goining projects
alias backend='cd /Users/abhijayrajvansh/Desktop/server-side-programming'
alias portfolio='cd /Users/abhijayrajvansh/Desktop/portfolio.js'
start_portfolio () {
  cd /Users/abhijayrajvansh/Desktop/portfolio.js
  code .
  ppd
}

kk; newSessionNotification;
# End of the document