# username and root access
alias greet="echo New Session Started, Welcome Back Mr. Rajvansh!"
alias reload='source ~/.zshrc'

# zsh-autosuggestions
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# {PROMPT='%n@%m %1~ %#}Default ZSH PROMPT
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%F{white}on%f %F{cyan}git:(%f%F{red}%b%f%F{cyan})%f '

setopt PROMPT_SUBST
# prompt v1
# PROMPT='%F{green}[%*]%f: %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f %F{yellow}$❯%f '

# prompt v2
PROMPT='
%F{green}[%*]%f: %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f
%B%F{green}❯%f%b '

# to hide and reveal desktop icons (mac machines)
alias showdesktop='defaults write com.apple.finder CreateDesktop true; killall Finder'
alias hidedesktop='defaults write com.apple.finder CreateDesktop false; killall Finder'  

# Define color codes
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

alias greentick='echo -n \[${GREEN}✔${RESET}\]" "'
alias redcross='echo -n \[${RED}✘${RESET}\]" "'
  
# navigation   
alias la='ls -l -G'
alias ll='ls -al -G'
alias l='la'
alias kk='clear' 
alias oo='open .'
alias zz='cd ..'
alias xx='exit'

# data science
alias count-files='ls -1 | wc -l'

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
alias ppx='pnpm dlx'
alias ppr='pnpm run'
alias ppi='pnpm install'
alias ppa='pnpm add'
alias ppd='ppi; pnpm run dev'
alias pps='ppi; pnpm run start'
alias ppb='ppi; pnpm run build'

export PNPM_HOME="/Users/abhijayrajvansh/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Next.js related aliases
alias cna='pnpm create next-app@latest'

# Generate Templates

# backend
alias add-docker-postgres-pgadmin='curl https://raw.githubusercontent.com/abhijayrajvansh/backend-library/main/config/docker-postgres-pgadmin.yaml -o docker-compose.yml'
alias add-docker-postgres-adminer='curl https://raw.githubusercontent.com/abhijayrajvansh/backend-library/main/config/docker-postgres-adminer.yaml -o docker-compose.yml'
alias add-docker-postgres='curl https://raw.githubusercontent.com/abhijayrajvansh/backend-library/main/config/docker-postgres.yaml -o docker-compose.yml'
alias add-tsconfig-json='curl https://raw.githubusercontent.com/abhijayrajvansh/backend-library/main/config/tsconfig.json -o tsconfig.json'
alias add-drizzle-config='curl https://raw.githubusercontent.com/abhijayrajvansh/backend-library/main/config/drizzle.config.ts -o drizzle.config.ts'

# documentaions
gen_readme_template () {
  zsh /Users/abhijayrajvansh/programming-environment-2024/templates/gen_readme.sh
}

# Git aliases and functions
mygithub='https://github.com/abhijayrajvansh/'
alias re-init-git='rm -rf .git && git init'

alias gs='git status'
alias ga='git add . ; gs;'
alias gd='git diff'
alias gpl='git pull'
alias gcl='git clone'
alias gw='git switch'

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
init_gitcli_default_values () {
  default_remote=$(git remote)
  default_commit_msg="wagmi: bug fixes & improvements"
  default_push_branch=$(git rev-parse --abbrev-ref HEAD)
}

gc () {
  init_gitcli_default_values
  echo -n "Enter Commit (def- $default_commit_msg): "
  read commit_msg

  if [ -z "$commit_msg" ]; then
    commit_msg="$default_commit_msg"
  fi

  rm -rf .DS_Store
  git add .
  git status
  git commit -m "$commit_msg"
}

gp () {
  init_gitcli_default_values
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  RESET='\033[0m'

  echo -n "Enter Commit (def- $default_commit_msg): "
  read commit_msg

  echo -n "Enter Branch (def- $default_remote/$default_push_branch): "
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

  rm -rf .DS_Store
  git add .
  git status
  git commit -m "$commit_msg"
  git push $default_remote $push_branch
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
  gpush "update: audit push && improvements" main
}

gz () {
  cd /Users/abhijayrajvansh/programming-environment-2024
  git pull origin main;
  update_dev_configurations;
  echo "Reload .zshrc to reflect changes."
}

# neo vim
alias vimrc='nv ~/.config/nvim/init.vim; echo launching: neovim config'
alias nv='nvim'

# launching applications
alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"

# creat new files and launch code-in directories 
prg () {
  for arg in "$@"; do
    echo "launching: $arg"
    touch $arg
    code $arg
  done
}

# enable scripts or productivity
alias start-skip-script='cd /Users/abhijayrajvansh/Documents/skip-script; app'

# default directories
alias desktop="cd /Users/abhijayrajvansh/Desktop"
alias documents="cd /Users/abhijayrajvansh/Documents"
alias ss='cd /Users/abhijayrajvansh/Documents/screenshots'
alias developer="cd /Users/abhijayrajvansh/Developer"
alias downloads="cd /Users/abhijayrajvansh/Downloads"
alias movies="cd /Users/abhijayrajvansh/Movies"

# quick directories
alias myenv="cd /Users/abhijayrajvansh/programming-environment-2024"
alias archives="cd /Users/abhijayrajvansh/Archives"
alias github='cd /Users/abhijayrajvansh/Github'
alias resume='cd ~/Documents/resume'

# VS Code settings
alias code-setting='echo "launching: settings.json"; code /Users/abhijayrajvansh/Library/Application\ Support/Code/User/settings.json'
alias snippets='cd /Users/abhijayrajvansh/Library/Application\ Support/Code/User/snippets'
PATH=~/.console-ninja/.bin:$PATH

# linkedin portfolio stuff
alias linkedin="cd /Users/abhijayrajvansh/Linkedin"
alias certificates='cd /Users/abhijayrajvansh/Linkedin/certificates'

# quick aliases
alias apps='cd /Applications/'
alias dev='developer'
alias desk='desktop'
alias docs='documents'
alias pics='cd /Users/abhijayrajvansh/Pictures/pics'
alias rar='/Users/abhijayrajvansh/Documents/rar/rar'

# postgres database
alias local-postgres-server='echo "DATABASE_URL=postgresql://postgres:postgres@localhost:5432/postgres"'

# on goining development projects
alias start-portfolio-development='portfolio; code .; ppd'
alias portfolio='cd /Users/abhijayrajvansh/Desktop/portfolio.js'
alias backend='cd /Users/abhijayrajvansh/Desktop/backend-library'

# on session load / startup commands:
kk; # clear history, logs and junks
greet; # respect your master, ofc 


# End of the document

# config archives
# alias starship-init='eval "$(starship init zsh)"'
