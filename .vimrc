" Portable Vim config for CTF / Attack-Defence.
" Neovim uses ~/.config/nvim instead; this file is the fallback for plain vim.

scriptencoding utf-8
set nocompatible
filetype plugin indent on
syntax on

" ---- display ---------------------------------------------------------------
set number
set relativenumber
set cursorline
set scrolloff=5
set sidescrolloff=5
set numberwidth=4
set showcmd
set ruler
set laststatus=2
set wildmenu
set wildmode=longest:full,full
set display=truncate
set wrap
set linebreak
set breakindent
set list
set listchars=tab:»·,trail:·,extends:›,precedes:‹,nbsp:␣
set colorcolumn=100

if exists('+termguicolors')
    set termguicolors
endif
silent! colorscheme habamax

" ---- editing ---------------------------------------------------------------
set encoding=utf-8
set fileencoding=utf-8
set backspace=indent,eol,start
set autoindent
set smartindent
set shiftround
set tabstop=4
set shiftwidth=4
set softtabstop=4
set expandtab
set virtualedit=block
set nrformats=hex
set mouse=a
if has('clipboard')
    set clipboard=unnamedplus,unnamed
endif
set hidden
set confirm
set noerrorbells
set visualbell
set t_vb=
set history=1000
set undolevels=1000
set updatetime=300
set completeopt=menuone,noinsert,noselect
set pumheight=10

" ---- search ----------------------------------------------------------------
set ignorecase
set smartcase
set incsearch
set hlsearch

" ---- files -----------------------------------------------------------------
set noswapfile
set nobackup
set nowritebackup
set undofile
set undodir=~/.vim/undo//
set backupdir=~/.vim/backup//
set directory=~/.vim/swap//
set viminfo='100,<50,s10,h
set tags=./tags;,tags
set path+=**
set wildignore=*.pyc,__pycache__/*,.git/*,node_modules/*

silent! call mkdir(expand('~/.vim/undo'), 'p')
silent! call mkdir(expand('~/.vim/backup'), 'p')
silent! call mkdir(expand('~/.vim/swap'), 'p')

" ---- splits ----------------------------------------------------------------
set splitright
set splitbelow

" ---- filetype tweaks -------------------------------------------------------
autocmd FileType make setlocal noexpandtab
autocmd FileType yaml,json setlocal tabstop=2 shiftwidth=2 softtabstop=2 expandtab
autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab
autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   execute "normal! g`\"" |
    \ endif

" ---- quality of life -------------------------------------------------------
let mapleader = " "
nnoremap <leader>w :w<CR>
nnoremap <leader>h :nohlsearch<CR>
nnoremap <F2> :set paste!<CR>
nnoremap <F3> :set number! relativenumber!<CR>
nnoremap <F4> :set list!<CR>
nnoremap Y y$
vnoremap < <gv
vnoremap > >gv
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>a

" Status line: file, flags, encoding, position.
set statusline=%f%m%r%h%w\ %{&fileformat}\ %{&fileencoding!=''?&fileencoding:&encoding}\ [%l/%L,%c]\ %P
