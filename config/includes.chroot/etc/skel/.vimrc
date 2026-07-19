# CoolOS Neovim Configuration

" General
set nocompatible
set encoding=utf-8
set fileencoding=utf-8
set number
set relativenumber
set cursorline
set showcmd
set showmode
set laststatus=2
set wildmenu
set wildmode=longest,full
set ruler
set cmdheight=1
set hidden
set nobackup
set nowritebackup
set noswapfile
set autoread
set autowrite
set confirm
set backspace=indent,eol,start
set mouse=a
set clipboard=unnamedplus
set wildignore=*.o,*~,*.pyc,*/.git/*,*/.hg/*,*/.svn/*

" Search
set hlsearch
set incsearch
set ignorecase
set smartcase
set gdefault

" Indentation
set autoindent
set smartindent
set shiftwidth=4
set tabstop=4
set softtabstop=4
set expandtab
set shiftround
set nowrap
set linebreak
set noswapfile

" Colors
syntax enable
set background=dark
colorscheme desert

" Status line
set statusline=
set statusline+=\ %M
set statusline+=\ %r
set statusline+=\ %F
set statusline+=%=
set statusline+=\ %y
set statusline+=\ %l/%L
set statusline+=\ (%p%%)
set statusline+=\ [%{&fileencoding?&fileencoding:&encoding}]
set statusline+=\ [%{&fileformat}]

" Key mappings
let mapleader=","

" Quick save and quit
nmap <leader>w :w!<cr>
nmap <leader>q :q!<cr>

" Split navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Resize splits
nnoremap <C-Up> :resize +3<cr>
nnoremap <C-Down> :resize -3<cr>
nnoremap <C-Left> :vertical resize -3<cr>
nnoremap <C-Right> :vertical resize +3<cr>

" Buffer navigation
nnoremap <leader>l :bnext<cr>
nnoremap <leader>h :bprevious<cr>

" Tab navigation
nnoremap <leader>t :tabnew<cr>
nnoremap <leader>n :tabnext<cr>
nnoremap <leader>p :tabprevious<cr>

" Clear search highlighting
nnoremap <leader>/ :nohlsearch<cr>

" Visual mode
vnoremap < <gv
vnoremap > >gv

" Move lines up and down
nnoremap <A-j> :m .+1<cr>==
nnoremap <A-k> :m .-2<cr>==
inoremap <A-j> <Esc>:m .+1<cr>==gi
inoremap <A-k> <Esc>:m .-2<cr>==gi
vnoremap <A-j> :m '>+1<cr>gv=gv
vnoremap <A-k> :m '<-2<cr>gv=gv

" Auto commands
if has("autocmd")
    autocmd BufRead,BufNewFile *.py setlocal tabstop=4 shiftwidth=4 textwidth=79 expandtab
    autocmd BufRead,BufNewFile *.js,*.html,*.css,*.json setlocal tabstop=2 shiftwidth=2
    autocmd BufRead,BufNewFile *.md setlocal spell
    autocmd BufRead,BufNewFile Makefile setlocal noexpandtab
    autocmd BufWritePost .vimrc source $MYVIMRC
endif

" File type specific settings
filetype plugin indent on

" Plugins (if using vim-plug)
" call plug#begin('~/.vim/plugged')
" Plug 'tpope/vim-surround'
" Plug 'tpope/vim-commentary'
" Plug 'vim-airline/vim-airline'
" Plug 'vim-airline/vim-airline-themes'
" call plug#end()
