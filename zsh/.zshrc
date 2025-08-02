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
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%F{white}on%f %F{cyan}git:(%f%F{red}%b%f%F{cyan})%f '
setopt PROMPT_SUBST

# Function to show Python venv
function virtualenv_info {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "%F{yellow}(${VIRTUAL_ENV:t})%f "
  elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    echo "%F{yellow}(${CONDA_DEFAULT_ENV})%f "
  fi
}

# prompt style v2
PROMPT='
%F{green}[%*]%f: $(virtualenv_info)%F{blue}%~%f %F{red}${vcs_info_msg_0_}%f
%B%F{green}❯%f%b '

# Default ZSH PROMPT v0: 
# {PROMPT='%n@%m %1~ %#}

# prompt style v1
# PROMPT='%F{green}[%*]%f: %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f %F{yellow}$❯%f '


# hide and reveal desktop icons
alias reveal-desktop-icons='defaults write com.apple.finder CreateDesktop true; killall Finder'
alias hide-desktop-icons='defaults write com.apple.finder CreateDesktop false; killall Finder' 

# quick actions
alias la='ls -l -G'
alias l='la'
alias ll='ls -al -G'
alias kk='clear' 
alias oo='open .'
alias xx='exit'
alias zz='cd ..'
alias zzz='cd ../../'
alias count-files='ls -1 | wc -l'
alias show-inet='ifconfig | grep "inet "'


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
alias ppt='pp run test'
alias ppg='pp pg'

# bun
alias bb='bun'
alias bbx='bunx'
alias bbr='bun run'
alias bbi='bun i'
alias bbui='bun remove'
alias bba='bun i'
alias bbd='bbi; bun run dev'
alias bbs='bbi; bun run start'
alias bbb='bbi; bun run build'
alias bbw='bbi; bun run watch'
alias bbs='bbi; bun run build && bun run start'
alias bbl='bbi; bun run lint'
alias bbt='bbi; bun run test'
alias bbg='bb pg'

export PNPM_HOME="/Users/abhijayrajvansh/Library/pnpm"
export PATH="$PNPM_HOME:$PATH"

# next.js configs
alias cna='pnpm create next-app@latest'

# core computer use
alias execute_take_ss_script='tsx /Users/abhijayrajvansh/Desktop/take-ss.ts'

# fullstack related templates configs
alias add-tsconfig-json='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-library/main/config/tsconfig.json -o tsconfig.json'
alias add-prettierrc-json='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-sdk/main/config/.prettierrc.json -o .prettierrc.json'
alias add-abhijay-debug-ts='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-sdk/refs/heads/main/config/abhijay-debug.ts -o abhijay-debug.ts'

# docker compose yaml
alias add-docker-postgres='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-library/main/config/docker-postgres.yaml -o docker-compose.yml'
alias add-docker-postgres-pgadmin='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-library/main/config/docker-postgres-pgadmin.yaml -o docker-compose.yml'
alias add-docker-postgres-adminer='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-library/main/config/docker-postgres-adminer.yaml -o docker-compose.yml'

# docker instances
alias docker_spin_ubuntu='docker run -d ubuntu tail -f /dev/null'

# drizzle config
alias add-drizzle-ts='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-sdk/refs/heads/main/config/drizzle-index.ts -o drizzle.ts'
alias add-drizzle-nextauth-schema='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-sdk/refs/heads/main/config/drizzle-nextauth-users-schema.ts -o schema.ts'
alias add-drizzle-config='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-library/main/config/drizzle.config.ts -o drizzle.config.ts'
alias print-drizzle-scripts='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-sdk/refs/heads/main/config/drizzle-scripts.json'

# documentation configs
alias add-readme-md='curl https://raw.githubusercontent.com/abhijayrajvansh/fullstack-sdk/main/config/README.md -o README.md'

# git configs and github aliases

mygithub='https://github.com/abhijayrajvansh'

alias re-init-git='rm -rf .git && git init'

alias gs='git status'
alias gd='git diff'
alias gpl='git pull'
alias gpf='git push --force-with-lease'
alias gcl='git clone'
alias gcl_here='git_clone_here'
alias gw='git switch'
alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"
alias gb='git branch'
alias gpp='git push fork'

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

git_clone_here() {
    if [ -z "$1" ]; then
        echo "Usage: clone_here <repo_url>"
        return 1
    fi

    git clone --depth=1 "$1" temp_repo && \
    cd temp_repo && rm -rf .git && cd .. && \
    mv temp_repo/* temp_repo/.* ./ 2>/dev/null;
    rm -rf temp_repo
}


# git global default values:
init_gitcli_default_values () {
  default_remote=origin
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
  echo "copying following configurations to remote environment:\n";
  greentick; echo "Copied rajvansh-cli and zsh config.";  cp-lzsh-rzsh;
  greentick; echo "Copied code settings.json & snippets."; cp-lcodesetting-rcodesetting; cp-lcodesnippets-rcodesnippets;
  greentick; echo "Copied neovim config."; cp-lnvcf-rnvcf;
  echo
}

update_dev_configurations () {
  echo "updating remote configurations to local environment:\n";
  greentick; echo "Updated rajvansh-cli and zsh config.";  cp-rzsh-lzsh;
  greentick; echo "Updated code settings.json & snippets."; cp-rcodesetting-lcodesetting; cp-rcodesnippets-lcodesnippets;
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


# create new files and launch code directories 
prg () {  
  for arg in "$@"; do
    echo "launching: $arg"
    touch $arg
    /Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code $arg
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

# vscode release settings 
alias code='/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin/code'
alias code-setting='echo "launching: settings.json"; code /Users/abhijayrajvansh/Library/Application\ Support/Code/User/settings.json'
alias code-snippets='cd /Users/abhijayrajvansh/Library/Application\ Support/Code/User/snippets'

# vscode insiders settings
alias code-in='/Applications/Visual\ Studio\ Code\ -\ Insiders.app/Contents/Resources/app/bin/code'
alias code-in-setting='echo "launching: settings.json"; code /Users/abhijayrajvansh/Library/Application\ Support/Code\ -\ Insiders/User/settings.json'
alias code-in-snippets='echo "launching: settings.json"; code /Users/abhijayrajvansh/Library/Application\ Support/Code\ -\ Insiders/User/snippets'

# portfolio related stuff
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
alias clients='cd /Users/abhijayrajvansh/Documents/clients'
alias freelancers='cd /Users/abhijayrajvansh/Documents/freelancers'
alias private-env='cd /Users/abhijayrajvansh/private-env'
alias icons='cd /Users/abhijayrajvansh/Archives/iconsbabbyyy'

# private automation flow
# jasmine - internal function
_jasmine_internal() {
  if [ $# -eq 0 ]; then
    echo "jasmine: hey ssup, im jasmine, abhijay's personal AI!"
    return
  fi

  local prompt="$*"
  tsx /Users/abhijayrajvansh/Desktop/project-jasmine/jasmine/index.ts "$prompt"
}

# jasmine alias with noglob to prevent ? and * expansion
alias jasmine='noglob _jasmine_internal'
alias start-tbot='cd /Users/abhijayrajvansh/Desktop/project-jasmine/tbot && zsh start-all.sh'

# local databases postgres
alias show-local-postgres-connection-string='echo "postgresql://postgres:postgres@localhost:5432/postgres"'

# mongodb
alias start-mongodb='brew services start mongodb-community'
alias stop-mongodb='brew services stop mongodb-community'

## LLMs and AI related 
# ollama local ai config
export OLLAMA_HOST=0.0.0.0:11434

# claude code cli and OSS
alias kimi='/Users/abhijayrajvansh/private-env/kimi/kimi.init.sh'


# on goining development projects
alias com='desk; cd com'
alias com-api='desk; cd com-api'
alias code-com='desk; cd com; code .;'
alias themis='desk; cd themis;'
alias code-themis='desk; cd themis; code .'
alias tms='cd /Users/abhijayrajvansh/Desktop/tms'
alias bms='cd /Users/abhijayrajvansh/Desktop/bms'

# react native env
alias start-android-emulator='/Users/abhijayrajvansh/Library/Android/sdk/emulator/emulator @Medium_Phone_API_35'

# jaiz logistics (client)
alias show-jaiz-logistics-creds='cat /Users/abhijayrajvansh/private-env/tms/jaiz-logistics-creds.txt'

# themis
alias show-themis-db-connection-string='cat /Users/abhijayrajvansh/private-env/themis/themis-db-connection-string'
alias show-themis-master-api-key='cat /Users/abhijayrajvansh/private-env/themis/master-api-key'
alias show-themis-env='cat /Users/abhijayrajvansh/private-env/themis/themis.env'

# private env
alias shh='private-env'
alias show-github-access-token='cat /Users/abhijayrajvansh/private-env/github/github-access-token'

createTreeContext() {
  rm -rf workspace-repo-structure-context.md
  echo '## Current Repository Tree Structure' >> workspace-repo-structure-context.md
  tree . --gitignore >> workspace-repo-structure-context.md
}

alias update-tree-context='createTreeContext'
alias utc='createTreeContext'
alias add-github-copilot-config='gcl_here https://github.com/abhijayrajvansh/github-copilot-config && zsh init.sh && utc'


# solana cli
export PATH="/Users/abhijayrajvansh/.local/share/solana/install/active_release/bin:$PATH"

# extras
alias starship-init='eval "$(starship init zsh)"'

# Added by Windsurf
export PATH="/Users/abhijayrajvansh/.codeium/windsurf/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/abhijayrajvansh/Desktop/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/abhijayrajvansh/Desktop/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/abhijayrajvansh/Desktop/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/abhijayrajvansh/Desktop/google-cloud-sdk/completion.zsh.inc'; fi


# on session load and startup commands:
kk; greetMe; # respect your master, ofc 

# End of the document
# bun completions