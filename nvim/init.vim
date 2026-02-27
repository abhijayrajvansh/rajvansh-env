:set number
:set autoindent
:set tabstop=4
:set shiftwidth=4
:set smarttab
:set softtabstop=4
:set mouse=a

" Configure a working Python host dynamically.
" UltiSnips requires the Neovim Python provider (pynvim).
let s:py3 = exepath('python3')
if !empty(s:py3)
  let g:python3_host_prog = s:py3
  silent! call system([s:py3, '-c', 'import pynvim'])
  let g:has_pynvim = (v:shell_error == 0)
else
  let g:has_pynvim = 0
endif

let s:plug_path = stdpath('data') . '/site/autoload/plug.vim'

" Bootstrap vim-plug if missing
if empty(glob(s:plug_path))
  silent execute '!curl -fLo ' . shellescape(s:plug_path) . ' --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

if filereadable(s:plug_path)
  execute 'source ' . fnameescape(s:plug_path)
endif

call plug#begin()

Plug 'https://github.com/vim-airline/vim-airline'  " airline status bar
Plug 'https://github.com/jiangmiao/auto-pairs'  " auto-pair closing brackets
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim' " fuzzy search for vim
Plug 'https://github.com/sainnhe/gruvbox-material/'  " gruvbox material theme
Plug 'https://github.com/projekt0n/github-nvim-theme' " github theme
Plug 'AbdelrahmanDwedar/awesome-nvim-colorschemes' " top neovim themes
if get(g:, 'has_pynvim', 0)
  Plug 'https://github.com/SirVer/ultisnips' " snippet extension
endif

call plug#end()

" nvim editor theme
silent! colorscheme github_dark_default

" Shortcut & Hotkeys mapping

" fuzzy searching buffer files
inoremap <C-p> <Esc>:GFiles<Cr>
nnoremap <C-p> <Esc>:GFiles<Cr>

" file tree
inoremap <C-b> <Esc>:Lex<Cr>:vertical resize 50<Cr>
nnoremap <C-b> <Esc>:Lex<Cr>:vertical resize 50<Cr>

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

" --- FZF: enhanced fuzzy finding ---
" Use ripgrep for fast file listing (includes hidden, ignores .git)
let $FZF_DEFAULT_COMMAND = "rg --files --hidden --follow -g '!.git' 2>/dev/null"
let $FZF_CTRL_T_COMMAND = $FZF_DEFAULT_COMMAND

" FZF window + preview settings
let g:fzf_layout = { 'down': '40%' }
let g:fzf_preview_window = [ 'right:50%', 'ctrl-/' ]

" Handy fuzzy-find keymaps (fzf.vim)
" Leader remains default (\\) unless you’ve set it elsewhere
nnoremap <leader>ff :Files<CR>
nnoremap <leader>fg :Rg<CR>
nnoremap <leader>fb :Buffers<CR>
nnoremap <leader>fl :BLines<CR>
nnoremap <leader>fh :History<CR>

" Quit all without saving, no prompt
command! XX qa!
command! WQ wq
