# author: https://abhijayrajvansh.com

# identity configs
alias greetMe="bash /Users/abhijayrajvansh/rajvansh-env/zsh/welcome.sh"
alias reload='source ~/.zshrc'
alias rr='reload'

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


# ================================================================
# =================== ZSH PROMPT CONFIGURATION =================
# ================================================================

# ============= PROMPT CORE SETUP =============

# Load version control system info
autoload -Uz vcs_info
setopt PROMPT_SUBST

# Enhanced git info with status indicators
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' get-revision true
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr "%F{green} ●%f"
zstyle ':vcs_info:*' unstagedstr "%F{red} ●%f"
zstyle ':vcs_info:git:*' formats '%F{white}on%f %F{cyan}git:(%f%F{red}%b%f%F{cyan})%f%c%u'
zstyle ':vcs_info:git:*' actionformats '%F{white}on%f %F{cyan}git:(%f%F{red}%b%f%F{yellow}|%a%f%F{cyan})%f%c%u'

# ============= PROMPT COMPONENT FUNCTIONS =============

# Function to show Python virtual environment
function virtualenv_info {
  if [[ -n "$VIRTUAL_ENV" ]]; then
    echo "%F{yellow}(py:${VIRTUAL_ENV:t})%f "
  elif [[ -n "$CONDA_DEFAULT_ENV" ]]; then
    echo "%F{yellow}(conda:${CONDA_DEFAULT_ENV})%f "
  fi
}

# Function to show Node.js version
function node_info {
  # Node.js version display disabled
  return
}

# Function to show git status indicators
function git_status_info {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    # ahead/behind arrows removed for faster prompt
    echo ""
  fi
}

# Function to show background jobs
function jobs_info {
  local job_count=$(jobs | wc -l | tr -d ' ')
  if [[ "$job_count" -gt 0 ]]; then
    echo "%F{yellow}[bg:$job_count]%f "
  fi
}

# Function to show directory permissions
function dir_permissions {
  if [[ ! -w "$PWD" ]]; then
    echo "%F{red}🔒%f"
  fi
}

# Show username when in home, otherwise mimic %1~ behavior
function prompt_cwd {
  if [[ "$PWD" == "$HOME" ]]; then
    print -n -- "$USER"
  else
    print -Pn "%1~"
  fi
}

# Function to show battery status (macOS)
function battery_info {
  if command -v pmset &> /dev/null; then
    local battery_percent=$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)
    local power_source=$(pmset -g batt | grep -o "AC Power\|Battery Power")
    
    if [[ -n "$battery_percent" ]]; then
      local battery_icon
      if [[ "$power_source" == "AC Power" ]]; then
        battery_icon="🔌"
      elif [[ "$battery_percent" -gt 80 ]]; then
        battery_icon="🔋"
      elif [[ "$battery_percent" -gt 50 ]]; then
        battery_icon="🔋"
      elif [[ "$battery_percent" -gt 20 ]]; then
        battery_icon="🪫"
      else
        battery_icon="%F{red}🪫%f"
      fi
      echo "$battery_icon$battery_percent%% "
    fi
  fi
}

# Function to show return code of last command
function return_code_info {
  echo "%(?..%F{red}[%?]%f )"
}

# Quick status widget for optional prompt extras
prompt_extras_widget() {
  local extras=""
  local battery=$(battery_info)
  [[ -n $battery ]] && extras+="$battery"
  local jobs=$(jobs_info)
  [[ -n $jobs ]] && extras+="$jobs"
  local venv=$(virtualenv_info)
  [[ -n $venv ]] && extras+="$venv"

  if [[ -n $extras ]]; then
    zle -M "${extras% }"
  else
    zle -M "No extra status"
  fi
}

if [[ -o interactive ]]; then
  zle -N prompt_extras_widget
  bindkey '^G' prompt_extras_widget
fi

# ============= PROMPT UPDATE FUNCTION =============

# Precmd function to update vcs_info and other dynamic content
precmd() { 
  vcs_info
}

# ============= PROMPT STYLE =============

# Enhanced prompt style (default and only style)
PROMPT='%F{green}[%D{%H:%M:%S}]%f $(return_code_info)%F{blue}$(prompt_cwd)%f$(dir_permissions) %F{red}${vcs_info_msg_0_}%f$(git_status_info) %B%F{green}❯ %f%b'

# ============= ESSENTIAL PROMPT ALIASES =============

# System status
alias status='echo "\n$(date)\nUptime: $(uptime)\nDisk: $(df -h / | tail -1 | awk "{print \$5\" used\"}")\nMemory: $(top -l 1 | grep PhysMem | awk "{print \$2\" used\"}")\n"'

# ================================================================
# ================ END ZSH PROMPT CONFIGURATION =================
# ================================================================


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
alias count-files='printf "total files: %s\n" "$(ls -1 | wc -l | tr -d "[:space:]")"'
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

# npm (Node Package Manager)
alias nn='npm'
alias nnx='npx'
alias nnr='npm run'
alias nni='npm install'
alias nnui='npm uninstall'
alias nna='npm install'
alias nnd='nni; npm run dev'
alias nns='nni; npm run start'
alias nnb='nni; npm run build'
alias nnw='nni; npm run watch'
alias nnbs='nni; npm run build && npm run start'
alias nnl='nni; npm run lint'
alias nnt='nni; npm run test'
alias nng='nn pg'

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

# serveo tunnel function
forward_port() {
  local port=${1:-3000}
  echo "Creating tunnel for localhost:$port via serveo.net..."
  ssh -R 80:localhost:$port serveo.net
}

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
alias gr='git restore .'
alias gd='git diff'
alias gpl='git pull'
alias gpf='git push --force-with-lease'
alias gcl='git clone'
alias gw='git switch'
alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"
alias gb='git branch'
alias gpp='git push fork'

## github related aliases

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

gcl_here() {
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

  if [ -z "$commit_msg" ]; then
    commit_msg="$default_commit_msg"
  fi

  echo ""
  echo -e "Using git commit message: ${GREEN}$commit_msg${RESET}"
  echo "Using git push branch: ${RED}$default_remote/$default_push_branch${RESET}"
  echo ""

  rm -rf .DS_Store
  git add .
  git status
  git commit -m "$commit_msg"
  git push $default_remote $default_push_branch
}

## github copilot related aliases
alias ghce='gh copilot explain'
alias ghcs='gh copilot suggest'

# zsh configfunctions and Commandline:
alias zshrc='code ~/.zshrc; echo launching: zsh config'

# updating .zshrc file and code snippets in git remote repo:
alias cp-lzsh-rzsh='cp /Users/abhijayrajvansh/.zshrc /Users/abhijayrajvansh/rajvansh-env/zsh'
alias cp-rzsh-lzsh='cp /Users/abhijayrajvansh/rajvansh-env/zsh/.zshrc /Users/abhijayrajvansh/'

# VSCode settings and snippets
alias cp-lcodesetting-rcodesetting='cp -r /Users/abhijayrajvansh/Library/Application\ Support/Code/User/settings.json /Users/abhijayrajvansh/rajvansh-env/vscode/'
alias cp-rcodesetting-lcodesetting='cp -r /Users/abhijayrajvansh/rajvansh-env/vscode/settings.json /Users/abhijayrajvansh/Library/Application\ Support/Code/User/'

alias cp-lcodesnippets-rcodesnippets='cp -r /Users/abhijayrajvansh/Library/Application\ Support/Code/User/snippets /Users/abhijayrajvansh/rajvansh-env/vscode/'
alias cp-rcodesnippets-lcodesnippets='cp -r /Users/abhijayrajvansh/rajvansh-env/vscode/snippets /Users/abhijayrajvansh/Library/Application\ Support/Code/User/'

# Trae IDE settings and snippets
alias cp-ltraesetting-rtraesetting='cp -r /Users/abhijayrajvansh/Library/Application\ Support/Trae/User/settings.json /Users/abhijayrajvansh/rajvansh-env/trae/'
alias cp-rtraesetting-ltraesetting='cp -r /Users/abhijayrajvansh/rajvansh-env/trae/settings.json /Users/abhijayrajvansh/Library/Application\ Support/Trae/User/'

alias cp-ltraesnippets-rtraesnippets='cp -r /Users/abhijayrajvansh/Library/Application\ Support/Trae/User/snippets /Users/abhijayrajvansh/rajvansh-env/trae/'
alias cp-rtraesnippets-ltraesnippets='cp -r /Users/abhijayrajvansh/rajvansh-env/trae/snippets /Users/abhijayrajvansh/Library/Application\ Support/Trae/User/'

# Neovim config
alias cp-lnvcf-rnvcf='cp -r ~/.config/nvim ~/rajvansh-env/'
alias cp-rnvcf-lnvcf='cp -r ~/rajvansh-env/nvim ~/.config/'

copy_localenv_to_remoteenv () {
  echo "copying following configurations to remote environment:\n";
  greentick; echo "Copied rajvansh-cli and zsh config."; cp-lzsh-rzsh;
  greentick; echo "Copied VSCode settings.json & snippets."; cp-lcodesetting-rcodesetting; cp-lcodesnippets-rcodesnippets;
  greentick; echo "Copied Trae IDE settings.json & snippets."; cp-ltraesetting-rtraesetting; cp-ltraesnippets-rtraesnippets;
  greentick; echo "Copied neovim config."; cp-lnvcf-rnvcf;
  echo
}

copy_remoteenv_to_localenv () {
  echo "copying following configurations from remote environment:\n";
  greentick; echo "Copied rajvansh-cli and zsh config."; cp-rzsh-lzsh;
  greentick; echo "Copied VSCode settings.json & snippets."; cp-rcodesetting-lcodesetting; cp-rcodesnippets-lcodesnippets;
  greentick; echo "Copied Trae IDE settings.json & snippets."; cp-rtraesetting-ltraesetting; cp-rtraesnippets-ltraesnippets;
  greentick; echo "Copied neovim config."; cp-rnvcf-lnvcf;
  echo
}

pz () {
  cd /Users/abhijayrajvansh/rajvansh-env
  copy_localenv_to_remoteenv;
  gpush "update: audit push && improvements" main
}

# New function to pull configurations from remote
gz () {
  cd /Users/abhijayrajvansh/rajvansh-env
  git pull origin main
  copy_remoteenv_to_localenv;
  echo "> Successfully pulled and applied remote configurations"
}

# neo vim
alias vimrc='nv ~/.config/nvim/init.vim; echo launching: neovim config'
alias nv='nvim'


# Code editor launchers and helpers
CODE_LAUNCHER_VSCODE="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
CODE_LAUNCHER_VSCODE_INSIDERS="/Applications/Visual Studio Code - Insiders.app/Contents/Resources/app/bin/code"
CODE_LAUNCHER_TRAE="/Applications/Trae.app/Contents/Resources/app/bin/trae"
CODE_LAUNCHER_CURSOR="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"

if [[ -n "${primary_code_editor:-}" ]]; then
  PRIMARY_CODE_EDITOR="$primary_code_editor"
else
  : "${PRIMARY_CODE_EDITOR:=trae}"
fi

if [[ "$(hostname)" == "Abhijays-MacBook-Air.local" ]]; then
  PRIMARY_CODE_EDITOR="cursor"
fi

typeset -g primary_code_editor="$PRIMARY_CODE_EDITOR"

__code_cli_for() {
  local choice="${1:-${primary_code_editor:-${PRIMARY_CODE_EDITOR:-trae}}}"

  case "$choice" in
    vscode|code|visual-studio-code)
      printf '%s' "$CODE_LAUNCHER_VSCODE"
      ;;
    vscode-insiders|code-insiders|insiders)
      printf '%s' "$CODE_LAUNCHER_VSCODE_INSIDERS"
      ;;
    cursor)
      printf '%s' "$CODE_LAUNCHER_CURSOR"
      ;;
    trae|marscode)
      printf '%s' "$CODE_LAUNCHER_TRAE"
      ;;
    *)
      if [[ -n "$CODE_CUSTOM_LAUNCHER" ]]; then
        printf '%s' "$CODE_CUSTOM_LAUNCHER"
        return 0
      fi

      printf 'primary code editor %q is not configured\n' "$choice" >&2
      return 1
      ;;
  esac
}

__code_settings_path_for() {
  local choice="${1:-${primary_code_editor:-${PRIMARY_CODE_EDITOR:-trae}}}"

  case "$choice" in
    vscode|code|visual-studio-code)
      printf '%s' "$HOME/Library/Application Support/Code/User/settings.json"
      ;;
    vscode-insiders|code-insiders|insiders)
      printf '%s' "$HOME/Library/Application Support/Code - Insiders/User/settings.json"
      ;;
    cursor)
      printf '%s' "$HOME/Library/Application Support/Cursor/User/settings.json"
      ;;
    trae|marscode)
      printf '%s' "$HOME/Library/Application Support/Trae/User/settings.json"
      ;;
    *)
      if [[ -n "$CODE_CUSTOM_SETTINGS_PATH" ]]; then
        printf '%s' "$CODE_CUSTOM_SETTINGS_PATH"
        return 0
      fi

      printf 'primary code editor %q does not have a known settings path\n' "$choice" >&2
      return 1
      ;;
  esac
}

set-primary-code-editor() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: set-primary-code-editor <vscode|vscode-insiders|cursor|trae>" >&2
    return 1
  fi

  local choice="$1"

  if ! __code_cli_for "$choice" >/dev/null 2>&1; then
    echo "primary code editor '$choice' is not configured" >&2
    return 1
  fi

  PRIMARY_CODE_EDITOR="$choice"
  export PRIMARY_CODE_EDITOR
  typeset -g primary_code_editor="$choice"
  echo "Primary code editor set to $choice"
}

function code {
  local cli
  cli="$(__code_cli_for)" || return 1
  "$cli" "$@"
}

# create new files and launch code directories 
prg () {  
  for arg in "$@"; do
    echo "launching: $arg"
    touch -- "$arg"
    code "$arg"
  done
}

# default directories
alias desktop="cd /Users/abhijayrajvansh/Desktop"
alias dk='desk'; # cant type lol
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
alias projects='cd /Users/abhijayrajvansh/Developer/projects'

# on goining development projects
alias com='desk; cd com'
alias tms='desk; cd tms'
alias orca='desk; cd orca'
alias njf='desk; cd not-just-flowers'
alias gor='desk; cd guess-or-regret'
alias binsr='desk; cd binsr-inspect'


# comyui setups
alias workflows='cd /Users/abhijayrajvansh/Desktop/workflows'
alias workspace='cd /Users/abhijayrajvansh/Desktop/workspace'

# vscode release settings 
unalias code-setting 2>/dev/null
code-setting() {
  local choice="${1:-${primary_code_editor:-${PRIMARY_CODE_EDITOR:-trae}}}"
  local cli
  local settings_path

  if ! cli="$(__code_cli_for "$choice")"; then
    return 1
  fi

  if ! settings_path="$(__code_settings_path_for "$choice")"; then
    return 1
  fi

  echo "launching ($choice): settings.json"
  "$cli" "$settings_path"
}
alias code-snippets='cd /Users/abhijayrajvansh/Library/Application\ Support/Code/User/snippets'

# vscode insiders settings
alias code-in='/Applications/Visual\ Studio\ Code\ -\ Insiders.app/Contents/Resources/app/bin/code'
alias code-in-setting='echo "launching: settings.json"; code-in /Users/abhijayrajvansh/Library/Application\ Support/Code\ -\ Insiders/User/settings.json'
alias code-in-snippets='echo "launching: settings.json"; code-in /Users/abhijayrajvansh/Library/Application\ Support/Code\ -\ Insiders/User/snippets'

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
alias icons='cd /Users/abhijayrajvansh/Archives/iconsbabbyyy'
alias finance='cd /Users/abhijayrajvansh/Documents/finance'

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
alias horizon='/Users/abhijayrajvansh/private-env/horizon/horizon.init.sh'

## TS Term
alias tt='tsx /Users/abhijayrajvansh/Desktop/ts-term/background-executor.ts'

# react native env

# List only iOS simulators (with version headers)
print_all_onlineSimulators() {
  xcrun simctl list devices | awk '
    BEGIN {
      green = "\033[0;32m"
      red = "\033[0;31m"
      reset = "\033[0m"
    }
    /^== Devices ==$/ {
      print; in_devices = 1; next
    }
    in_devices && /^-- / {
      if ($0 ~ /-- iOS /) {
        in_ios = 1
        print
      } else {
        in_ios = 0
      }
      next
    }
    in_devices && in_ios {
      if ($0 ~ /unavailable/) {
        gsub(/^ +/, "", $0)
        print "❌ " $0 reset
      } else {
        gsub(/^ +/, "", $0)
        print "✅ " $0 reset
      }
    }
  '
}

## android and ios | react native expo development 
alias list-ios-simulators='print_all_onlineSimulators'
alias list-android-emulators='/Users/abhijayrajvansh/Library/Android/sdk/emulator/emulator -list-avds'

# Android & iOS Emulator shortcuts
alias start-android-emulator='~/Library/Android/sdk/emulator/emulator -avd Pixel_9_Pro'
alias start-ios-emulator='open -a Simulator && xcrun simctl boot "iPhone 16e"'


# jaiz logistics (client)
alias show-jaiz-logistics-creds='cat /Users/abhijayrajvansh/private-env/tms/jaiz-logistics-creds.txt'
alias show-wheelseye-credentials='cat /Users/abhijayrajvansh/private-env/tms/wheelseye-credentials.txt'

# themis
alias show-themis-db-connection-string='cat /Users/abhijayrajvansh/private-env/themis/themis-db-connection-string'
alias show-themis-master-api-key='cat /Users/abhijayrajvansh/private-env/themis/master-api-key'
alias show-themis-env='cat /Users/abhijayrajvansh/private-env/themis/themis.env'

# private env
alias pvt='cd /Users/abhijayrajvansh/private-env'
alias show-github-access-token='cat /Users/abhijayrajvansh/private-env/github.env'
alias show-chatgpt-credentials='cat /Users/abhijayrajvansh/private-env/openai/chatgpt-credentials.txt'
alias show-openrouter-api-key='pvt; cd openrouter; cat coding-apikey.txt'
alias show-civitai-access-token='cat /Users/abhijayrajvansh/private-env/civitai/access-token.txt'
alias show-hf-access-token='cat /Users/abhijayrajvansh/private-env/hf/access-token.txt'

createTreeContext() {
  # Create .github directory if it doesn't exist
  mkdir -p .github
  
  # Remove the file if it exists (no error if it doesn't exist)
  rm -f .github/workspace-repo-structure-context.md
  
  echo '## Current Repository Tree Structure' > .github/workspace-repo-structure-context.md
  tree . --gitignore >> .github/workspace-repo-structure-context.md
}

alias update-tree-context='createTreeContext'
alias utc='createTreeContext'
alias add-github-copilot-config='gcl_here https://github.com/abhijayrajvansh/github-copilot-config && zsh init.sh && utc'


# solana cli
export PATH="/Users/abhijayrajvansh/.local/share/solana/install/active_release/bin:$PATH"


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/abhijayrajvansh/Desktop/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/abhijayrajvansh/Desktop/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/abhijayrajvansh/Desktop/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/abhijayrajvansh/Desktop/google-cloud-sdk/completion.zsh.inc'; fi

# github askpass for non-interactive authentication in git

# >>> GitHub AskPass >>>
export GIT_ASKPASS="$HOME/private-env/git-askpass-github.sh"
export SSH_ASKPASS="$GIT_ASKPASS"
export GIT_TERMINAL_PROMPT=0
# <<< GitHub AskPass <<<

# Added by Codex CLI: jas alias
DEFAULT_JAS_ALIAS='Codex with YOLO'
alias jas='codex --yolo'
alias don='codex --yolo --profile openrouter'

# Playwright config for Codex/MCP
export PLAYWRIGHT_BROWSERS_PATH="$HOME/Library/Caches/ms-playwright"
export NODE_PATH="$(npm root -g)"

# # Java and Android SDKs
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=$ANDROID_HOME/emulator:$PATH

export PATH="$HOME/.local/bin:$PATH"
export JAVA_HOME=$(/usr/libexec/java_home -v 17)

## -- Execute On Every Zsh Session --
clear; greetMe;
