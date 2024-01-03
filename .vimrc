" general settings
filetype on
filetype plugin on
filetype indent on

" no anoying bells and whistles
set visualbell          " use a visual bell instead of an audible
set noerrorbells        " disables the error bells
set t_vb=               " disables the terminal bell

set showcmd             " 
set showmode            " show current mode
set showmatch           " show matching brackets
set colorcolumn=80      " ruler at end of line

set backspace=indent,eol,start   " backspace over everything in insert mode

syntax on               " enable syntax hilightning
set number              " line numbers
set expandtab           " tabs instead of spaces
set smarttab

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
