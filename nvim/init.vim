:set number
:set autoindent
:set tabstop=4
:set shiftwidth=4
:set smarttab
:set softtabstop=4
:set mouse=a

call plug#begin()

Plug 'https://github.com/vim-airline/vim-airline'  " airline status bar
Plug 'https://github.com/jiangmiao/auto-pairs'  " auto-pair closing brackets

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'https://github.com/sainnhe/gruvbox-material/'  " gruvbox material theme
Plug 'https://github.com/projekt0n/github-nvim-theme' " github theme

Plug 'AbdelrahmanDwedar/awesome-nvim-colorschemes' " top neovim themes


call plug#end()


" Hotkeys mapping
nnoremap <C-p> :GFiles<Cr>

