# username and root access
alias newSessionNotification="echo New Session Started, Current User is: abhijayrajvansh"
alias root="cd /Users/abhijayrajvansh/"

# reload: normal zshrc refresh reload
alias reload='clear && source ~/.zshrc'
alias rr='reload'

# zsh-autosuggestions
alias import-autosuggestions='source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh'
import-autosuggestions

# Define color codes
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'

alias greentick='echo -n ${GREEN}✔ ${RESET}'
alias redcross='echo -n ${RED}✘ ${RESET}'
  
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

# Perfomant Node Package Manager / PNPM
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
  myenv;
  copy_localenv_to_remoteenv;
  gpush "update: dev configs and improvements" main
}

gz () {
  myenv;
  git pull origin main;
  update_dev_configurations;
}

# {PROMPT='%n@%m %1~ %#}Default ZSH PROMPT
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%F{cyan}git:(%f%F{red}%b%f%F{cyan})%f'

setopt PROMPT_SUBST
PROMPT='%F{green}[%*]%f: %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f %F{yellow}$%f '

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
prg () {
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

alias projects="echo projects are shifted to notion."

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