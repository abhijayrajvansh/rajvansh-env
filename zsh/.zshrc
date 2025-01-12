# author: https://abhijayrajvansh.com


# identity configs
alias greetMe="echo New Session Started, Welcome Back Mr. Rajvansh!"
alias reload='source ~/.zshrc'


# color codes and ui variables
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


# zsh-autosuggestions
alias source-zsh_autosuggestions='source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh'


# custom zsh prompt status
# come more symbols:                                                                                                                         
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%F{white}on%f %F{cyan}git:(%f%F{red}%b%f%F{cyan})%f '
setopt PROMPT_SUBST

# prompt style v2
PROMPT='
%F{green}[%*]%f: %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f
%B%F{green}❯%f%b '

# Default ZSH PROMPT v0: 
# {PROMPT='%n@%m %1~ %#}

# prompt style v1
# PROMPT='%F{green}[%*]%f: %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f %F{yellow}$❯%f '


# hide and reveal desktop icons
alias showdesktop='defaults write com.apple.finder CreateDesktop true; killall Finder'
alias hidedesktop='defaults write com.apple.finder CreateDesktop false; killall Finder'  

# quick actions
alias la='ls -l -G'
alias l='la'
alias ll='ls -al -G'
alias kk='clear' 
alias oo='open .'
alias xx='exit'
alias zz='cd ..'
alias zzz='cd ../../../'
alias count-files='ls -1 | wc -l'


# python configs
alias python='python3'
alias app='python app.py'
alias py='python'
alias pip='pip3'


# Node Version Manager
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" 

# local installs and configurations

# git to text parser for llms: git2txt
alias git2txt='git2txt'
# get all commits and logs in a text file
alias git_print_all_logs='git log --pretty=format:"%h - %an, %ar : %s" > gitlog.txt'

# pnpm (Perfomant Node Package Manager)
alias pp='pnpm'
alias ppx='pnpm dlx'
alias ppr='pnpm run'
alias ppi='pnpm install'
alias ppui='pnpm uninstall'
alias ppa='pnpm add'
alias ppd='ppi; pnpm run dev'
alias pps='ppi; pnpm run start'
alias ppb='ppi; pnpm run build'
alias ppw='ppi; pnpm run watch'
alias ppbs='ppi; pnpm run build && pnpm run start'
alias ppl='ppi; pnpm run lint'

export PNPM_HOME="/Users/abhijayrajvansh/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# next.js configs
alias cna='pnpm create next-app@latest'

# fullstack related templates configs
alias add-tsconfig-json='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-library/main/config/tsconfig.json -o tsconfig.json'
alias add-prettierrc-json='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-sdk/main/config/.prettierrc.json -o .prettierrc.json'
alias add-abhijay-debug-ts='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-sdk/refs/heads/main/config/abhijay-debug.ts -o abhijay-debug.ts'

# docker compose yaml
alias add-docker-postgres='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-library/main/config/docker-postgres.yaml -o docker-compose.yml'
alias add-docker-postgres-pgadmin='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-library/main/config/docker-postgres-pgadmin.yaml -o docker-compose.yml'
alias add-docker-postgres-adminer='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-library/main/config/docker-postgres-adminer.yaml -o docker-compose.yml'

# drizzle config
alias add-drizzle-ts='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-sdk/refs/heads/main/config/drizzle-index.ts -o drizzle.ts'
alias add-drizzle-nextauth-schema='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-sdk/refs/heads/main/config/drizzle-nextauth-users-schema.ts -o schema.ts'
alias add-drizzle-config='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-library/main/config/drizzle.config.ts -o drizzle.config.ts'
alias print-drizzle-scripts='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-sdk/refs/heads/main/config/drizzle-scripts.json'

# documentation configs
alias add-readme-md='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-sdk/main/config/README.md -o README.md'

# git configs

mygithub='https://github.com/abhijayrajvansh'

alias re-init-git='rm -rf .git && git init'

alias gs='git status'
alias gd='git diff'
alias gpl='git pull'
alias gcl='git clone'
alias gw='git switch'

ga() {
  for arg in "$@"; do
    git add $arg
  done
  git status
}

gc() {
  for arg in "$@"; do
    git add $arg
  done
  echo -n "enter commit: "
  read commit_msg
  git commit -m "$commit_msg"
  git status
}

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

gca() {
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
alias cp-lzsh-rzsh='cp /Users/abhijayrajvansh/.zshrc /Users/abhijayrajvansh/rajvansh-env/zsh'
alias cp-rzsh-lzsh='cp /Users/abhijayrajvansh/rajvansh-env/zsh/.zshrc /Users/abhijayrajvansh/'

alias cp-lcodesetting-rcodesetting='cp -r /Users/abhijayrajvansh/Library/Application\ Support/Code/User/settings.json /Users/abhijayrajvansh/rajvansh-env/vscode/'
alias cp-rcodesetting-lcodesetting='cp -r /Users/abhijayrajvansh/rajvansh-env/vscode/settings.json /Users/abhijayrajvansh/Library/Application\ Support/Code/User/'

alias cp-lcodesnippets-rcodesnippets='cp -r /Users/abhijayrajvansh/Library/Application\ Support/Code/User/snippets /Users/abhijayrajvansh/rajvansh-env/vscode/'
alias cp-rcodesnippets-lcodesnippets='cp -r /Users/abhijayrajvansh/rajvansh-env/vscode/snippets /Users/abhijayrajvansh/Library/Application\ Support/Code/User/'

alias cp-lnvcf-rnvcf='cp -r ~/.config/nvim ~/rajvansh-env/'
alias cp-rnvcf-lnvcf='cp -r ~/rajvansh-env/nvim ~/.config/'

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
  cd /Users/abhijayrajvansh/rajvansh-env
  copy_localenv_to_remoteenv;
  gpush "update: audit push && improvements" main
}

gz () {
  cd /Users/abhijayrajvansh/rajvansh-env
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

# default directories
alias desktop="cd /Users/abhijayrajvansh/Desktop"
alias documents="cd /Users/abhijayrajvansh/Documents"
alias developer="cd /Users/abhijayrajvansh/Developer"
alias downloads="cd /Users/abhijayrajvansh/Downloads"
alias movies="cd /Users/abhijayrajvansh/Movies"

# quick directories
alias rajvansh-env="cd /Users/abhijayrajvansh/rajvansh-env"
alias archives="cd /Users/abhijayrajvansh/Archives"
alias github='cd /Users/abhijayrajvansh/Github'
alias obs='cd /Users/abhijayrajvansh/Documents/obs'
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
alias dev-notes='dev; cd dev-notes && oo .'
alias desk='desktop'
alias docs='documents'
alias pics='cd /Users/abhijayrajvansh/Pictures/pics'
alias wallpapers='cd /Users/abhijayrajvansh/Pictures/pics/wallpapers; oo'
alias rar='/Users/abhijayrajvansh/Documents/rar/rar'

# local databases

# postgres
alias local-docker-postgres='echo "DATABASE_URL=postgresql://postgres:postgres@localhost:5432/postgres"'

# ollama local ai config
export OLLAMA_HOST=0.0.0.0:11434

# on goining development projects
alias evaluate='cd /Users/abhijayrajvansh/Desktop/evaluate-ai'
alias dev-com='com; code .; ppd'

alias themis='desk; cd themis; code .'
#mongodb
alias start-mongodb='brew services start mongodb-community'
alias stop-mongodb='brew services stop mongodb-community'

themisMongodb='mongodb+srv://abhijay:RXsWo3QimwdawfPV@themiscluster.q2hty.mongodb.net/?retryWrites=true&w=majority&appName=themisCluster'
alias connect-themisMongodb='mongosh $themisMongodb'

# dev tools
alias private-keys='cd /Users/abhijayrajvansh/private-env'
alias create-tree-context='tree . --gitignore -o ./context/workspace-repo-structure.txt'

# solana cli
export PATH="/Users/abhijayrajvansh/.local/share/solana/install/active_release/bin:$PATH"


# on session load and startup commands:
kk; # cd to desktop and clear history, logs and junks
greetMe; # respect your master, ofc 

# End of the document

# ARCHIVED

# C/C++ GCC G++ Compliers
# deb () {
#   g++-12 -D ABHIJAY_DEBUG $1.cpp
#   ./a.out
# }

# run () {
#   g++-12 $1.cpp
#   ./a.out
# }


alias starship-init='eval "$(starship init zsh)"'

#solana gnu-tar error:
# chipset=$(sysctl -n machdep.cpu.brand_string)
# replacing bsd-tar with gnu-tar for solana validator (homebrew version)
# if [[ "$chipset" == *"Apple M2"* ]]; then
#   export PATH="/opt/homebrew/opt/gnu-tar/libexec/gnubin:$PATH"
# elif [[ "$chipset" == *"Intel"* ]]; then
#   export PATH="/usr/local/opt/gnu-tar/libexec/gnubin:$PATH"
# else
#   echo "unknown chipset"
# fi
#