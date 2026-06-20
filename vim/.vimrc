" .vimrc - Vim configuration file

" ============================================================================
" Plugins (vim-plug)
" ============================================================================
" Uncomment to enable plugin management
" call plug#begin()
" call plug#end()

" ============================================================================
" General Settings
" ============================================================================
filetype on
filetype plugin on
filetype indent on

" Disable annoying bells and whistles
set noerrorbells
set novisualbell
set t_vb=
set tm=500

" Display settings
set showcmd             " show command in status line
set showmode            " show current mode
set showmatch           " show matching brackets
set colorcolumn=80      " ruler at column 80 (code width limit)
set number              " show line numbers

" Clipboard integration
set clipboard^=unnamed,unnamedplus  " copy/paste from system register

" Syntax highlighting
syntax on

" ============================================================================
" Indentation
" ============================================================================
set expandtab           " use spaces instead of tabs
set smarttab
set smartindent
set shiftwidth=2        " 2-space indentation

" ============================================================================
" Search Settings
" ============================================================================
set ignorecase          " ignore case while searching
set smartcase           " be case-sensitive if pattern contains capitals
set showmatch           " show matching brackets
set hlsearch            " highlight search results
set incsearch           " search as you type
set magic               " use regex magic in patterns

" ============================================================================
" Wildmenu (Command-line completion)
" ============================================================================
set wildmenu
set wildmode=list:longest
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx

" ============================================================================
" Auto-closing braces and quotes
" ============================================================================
inoremap ( ()<Left>
inoremap [ []<Left>
inoremap { {}<Left>
inoremap " ""<Left>

" Smart CR: add newlines inside braces
inoremap <expr> <CR> search('{\%#}', 'n') ? "\<CR>\<CR>\<Up>\<C-f>" : "\<CR>"

" ============================================================================
" Colorscheme (optional)
" ============================================================================
" Uncomment your preferred theme
" colorscheme nord
