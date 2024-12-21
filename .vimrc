" plugins
call plug#begin()
" List your plugins here
call plug#end()

" general settings
filetype on
filetype plugin on
filetype indent on

" no anoying bells and whistles
set noerrorbells
set novisualbell
set t_vb=
set tm=500

set showcmd             " 
set showmode            " show current mode
set showmatch           " show matching brackets
set colorcolumn=80      " ruler at end of line

set clipboard^=unnamed,unnamedplus "copy/pase from and to system register

syntax on               " enable syntax hilightning
set number              " line numbers
set expandtab           " tabs instead of spaces
set smarttab
set smartindent
set shiftwidth=2        " indent with 2 spaces

" search settings
set ignorecase          " ignore case while searching
set smartcase           " explicit search for capital letters
set showmatch           " ???
set hlsearch            " highlight search results
set incsearch           " ???
set magic               " wtf? 

" wildmenu
set wildmenu
set wildmode=list:longest
set wildignore=*.docx,*.jpg,*.png,*.gif,*.pdf,*.pyc,*.exe,*.flv,*.img,*.xlsx

" auto-close braces, tags, ...
inoremap ( ()<Left>
inoremap [ []<Left>
inoremap { {}<Left>
inoremap " ""<Left>

inoremap <expr> <CR> search('{\%#}', 'n') ? "\<CR>\<CR>\<Up>\<C-f>" : "\<CR>" 

"colorscheme nord       " Theme
