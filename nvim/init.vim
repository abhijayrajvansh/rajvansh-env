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
Plug 'junegunn/fzf.vim' " fuzzy search for vim
Plug 'https://github.com/sainnhe/gruvbox-material/'  " gruvbox material theme
Plug 'https://github.com/projekt0n/github-nvim-theme' " github theme
Plug 'AbdelrahmanDwedar/awesome-nvim-colorschemes' " top neovim themes
Plug 'https://github.com/SirVer/ultisnips' " snippet extension

call plug#end()

" nvim editor theme
:colorscheme github_dark_tritanopia


" Shortcut & Hotkeys mapping

" fuzzy searching buffer files
inoremap <C-p> <Esc>:GFiles<Cr>
nnoremap <C-p> <Esc>:GFiles<Cr>

" file explorer tree
inoremap <C-b> <Esc>:Lex<Cr>:vertical resize 40<Cr>
nnoremap <C-b> <Esc>:Lex<Cr>:vertical resize 40<Cr>


" debug main.cpp file
inoremap <C-d> <Esc>:w<Cr><Esc>ggVG"+y<Esc>:terminal g++-12 -D ABHIJAY_DEBUG main.cpp && ./a.out<Cr>i
nnoremap <C-d> <Esc>:w<Cr><Esc>ggVG"+y<Esc>:terminal g++-12 -D ABHIJAY_DEBUG main.cpp && ./a.out<Cr>i

" run main.cpp file
inoremap <C-r> <Esc>:w<Cr>:terminal g++-12  main.cpp && ./a.out<Cr>i
nnoremap <C-r> <Esc>:w<Cr>:terminal g++-12  main.cpp && ./a.out<Cr>i

" save file
inoremap <C-s> <Esc>:w<Cr>
nnoremap <C-s> <Esc>:w<Cr>

" close file
inoremap <C-q> <Esc>:q<Cr>
nnoremap <C-q> <Esc>:q<Cr>

" select all
inoremap <C-a> <Esc>ggVG
nnoremap <C-a> <Esc>ggVG

" copy to system clipboard
vnoremap <C-c> "+y

let g:loaded_python3_provider=0