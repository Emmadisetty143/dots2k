" Load files using fzf
function! FZF() abort
    let l:tempname = tempname()
    execute 'silent !fzf --multi ' . '| awk ''{ print $1":1:0" }'' > ' . fnameescape(l:tempname)
    try
        execute 'cfile ' . l:tempname
        redraw!
    finally
        call delete(l:tempname)
    endtry
endfunction

" Native Buffer Tabline at the top (replaces standard tabline)
function! BufferTabLine() abort
    let l:s = ''
    let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val)')
    let l:current = bufnr('%')
    for l:buf in l:bufs
        if l:buf == l:current
            let l:s .= '%#TabLineSel#'
        else
            let l:s .= '%#TabLine#'
        endif
        let l:name = bufname(l:buf)
        let l:name = empty(l:name) ? '[No Name]' : fnamemodify(l:name, ':t')
        let l:modified = getbufvar(l:buf, '&modified') ? '*' : ''
        let l:s .= ' ' . l:buf . ' ' . l:name . l:modified . ' '
    endfor
    let l:s .= '%#TabLineFill#%T'
    return l:s
endfunction

set nocompatible   " Disable vi compatibility
set encoding=utf-8 " Use UTF-8
set showmatch      " Show matching brackets
set ignorecase     " Do case insensitive matching
set incsearch      " Show partial matches for a search phrase
set number         " Show numbers
set relativenumber " Show relative numbers
set nohlsearch     " clear highlights after search
set tabstop=4      " Tab size
set shiftwidth=4   " Indentation size
set softtabstop=4  " Tabs/Spaces interop
set expandtab      " Expands tab to spaces
set nomodeline     " Disable as a security precaution
set mouse=a        " Enable mouse mode
set hlsearch       " Enable search highlight
set wildmenu       " Enable wildmenu
set path+=**       " Search recursively with :find
set splitbelow     " Natural splits
set splitright
set autoindent     " Enable autoindent
set complete-=i    " Better completion
set smarttab       " Better tabs
set ttimeout       " Set timeout
set ttimeoutlen=100
set synmaxcol=500  " Syntax limit
set laststatus=2   " Always show status line
set ruler          " Show cursor position
set scrolloff=8    " Scroll offset
set sidescrolloff=5
set autoread       " Reload files on change
set tabpagemax=50  " More tabs
set history=1000   " More history
set viminfo^=!     " Better viminfo
set backspace=indent,eol,start " Delete everything
set formatoptions+=j " Delete comment character when joining
set listchars=tab:,nbsp:_,trail:,extends:>,precedes:<
set list           " Highlight non whitespace characters
set nrformats-=octal " 007 != 010
set sessionoptions-=options
set viewoptions-=option
set cursorline     " Highlight current line
set exrc           " Use vimrc from local dir
set secure         " Disable shell/write commands in local vimrc
set hidden         " Enable switching with modified buffers
set undolevels=999 " Lots of these
set undodir=$HOME/.local/state/vim/undo " Enable undo dir
set undofile       " Enable persistent undos across files
set tabline=%!BufferTabLine()
set showtabline=2 " Always show the buffer list at the top
setlocal spell spelllang=en "Set spell check language to en
setlocal spell! " Disable spellchecking by default
syntax enable      " Turn on syntax highlighting

" Have Vim jump to the last position when reopening a file
if has("autocmd")
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\""
endif

" Remove trailing whitespace on write
if has("autocmd")
    autocmd BufWritePre * %s/\s\+$//e
endif

let g:netrw_liststyle = 3
let g:netrw_banner = 0  " Hide help banner to match nvim-tree
let g:netrw_winsize = 25 " Match default Neovim explorer width
let g:netrw_browse_split = 4 " Open files in previous active window (retains sidebar)
let g:netrw_altv = 1         " Open vertical splits on the right
let g:netrw_list_hide = ''   " Show hidden files (dotfiles) by default

function! NetrwSettings() abort
    " a: Add new file (Vim standard: %)
    nmap <buffer> a %
    " A: Add new directory (Vim standard: d)
    nmap <buffer> A d
    " r: Rename file or directory (Vim standard: R)
    nmap <buffer> r R
    " d: Delete file or directory (Vim standard: D)
    nmap <buffer> d D
    " H: Toggle hidden files (Vim standard: gh)
    nmap <buffer> H gh
    " q: Toggle/close Lexplore sidebar cleanly
    nmap <buffer> q :Lexplore<CR>

    " Navigation & Opening Files
    " l: Toggle folder expand/collapse or open file (Vim standard: Enter)
    nmap <buffer> l <CR>
endfunction

augroup NetrwCustom
    autocmd!
    autocmd FileType netrw call NetrwSettings()
augroup END


" Keybindings
let mapleader = ' '
inoremap jj <Esc>
nmap Q :qa!<CR>
nmap <leader>e :Lexplore<CR>
nmap <leader>f :FZF<cr>
nmap <leader>qq :q<CR>
nmap <leader>qa :qa<CR>
nmap <leader>r :source ~/.vimrc<CR>
nmap <leader>s :setlocal spell!<CR>
nmap <leader>S :nohlsearch<CR>
nmap <leader>t :term<CR>
nmap <leader>ww :w<CR>
nmap <leader>x :wq<CR>
nmap H :bprevious<CR>
nmap L :bnext<CR>
nmap <C-h> <C-w>h
nmap <C-l> <C-w>l
nmap <C-j> <C-w>j
nmap <C-k> <C-w>k

" Copy Paste from System Clipboard (cross-platform, Wayland/X11 compatible)
set clipboard+=unnamedplus
vmap <Leader>yy "+y
map <Leader>pp mz:put! +<CR>`z

" Drag Visual selections
vnoremap K xkP`[V`]
vnoremap J xp`[V`]
vnoremap L >gv
vnoremap H <gv

" tmux true color fix
if (has("termguicolors"))
    set termguicolors
endif

" Always use terminal background
autocmd ColorScheme * highlight! Normal ctermbg=NONE guibg=NONE
autocmd ColorScheme * highlight! Terminal ctermbg=NONE guibg=NONE

" Tone down cursor line, status bar, and tabline highlight colors globally
autocmd ColorScheme * highlight CursorLine cterm=NONE ctermbg=235 guibg=#222530
autocmd ColorScheme * highlight StatusLine cterm=NONE ctermfg=245 ctermbg=235 guifg=#a6adc8 guibg=#252535
autocmd ColorScheme * highlight StatusLineNC cterm=NONE ctermfg=238 ctermbg=234 guifg=#585b70 guibg=#1e1e2e
autocmd ColorScheme * highlight TabLineSel cterm=NONE ctermfg=245 ctermbg=235 guifg=#a6adc8 guibg=#252535
autocmd ColorScheme * highlight TabLine cterm=NONE ctermfg=238 ctermbg=234 guifg=#585b70 guibg=#1e1e2e
autocmd ColorScheme * highlight TabLineFill cterm=NONE ctermbg=234 guibg=#1e1e2e

" Load colorscheme with fallback to built-in 'slate'
try
    colorscheme catppuccin
catch /^Vim\%((\a\+)\)\=:E185/
    colorscheme slate
endtry
