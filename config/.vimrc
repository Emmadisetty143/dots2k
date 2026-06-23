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
set clipboard+=unnamedplus " Copy Paste from System Clipboard
setlocal spell spelllang=en "Set spell check language to en
setlocal spell! " Disable spellchecking by default
syntax enable      " Turn on syntax highlighting

let g:netrw_liststyle = 3
let g:netrw_banner = 0  " Hide help banner to match nvim-tree
let g:netrw_winsize = 25 " Match default Neovim explorer width
let g:netrw_browse_split = 4 " Open files in previous active window (retains sidebar)
let g:netrw_altv = 1         " Open vertical splits on the right
let g:netrw_list_hide = ''   " Show hidden files (dotfiles) by default
let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.8 } } " FZF Floating Window Layout Configuration

" Have Vim jump to the last position when reopening a file
if has("autocmd")
    au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\""
endif

" Remove trailing whitespace on write
if has("autocmd")
    autocmd BufWritePre * %s/\s\+$//e
endif

" Highlight on yank (copy)
function! s:HighlightYank() abort
    if v:event.operator ==# 'y' && exists('*matchaddpos')
        let l:m = matchaddpos('Visual', range(line("'["), line("']")))
        call timer_start(150, {-> execute('silent! call matchdelete(' . l:m . ')')})
    endif
endfunction

augroup HighlightYank
    autocmd!
    autocmd TextYankPost * call s:HighlightYank()
augroup END

" cross platform clipboard support
if has('wsl')
    if executable('win32yank.exe')
        let s:win32yank = 'win32yank.exe'
    elseif executable('win32yank')
        let s:win32yank = 'win32yank'
    endif
endif

if exists('s:win32yank')
    exec 'vmap <Leader>yy :w !' . s:win32yank . ' -i --crlf<CR><CR>'
    exec 'map <Leader>pp mz:-1r !' . s:win32yank . ' -o --lf<CR>`z'
else
    vmap <Leader>yy "+y
    map <Leader>pp mz:put! +<CR>`z
endif

" Helper for buffer selection callback
function! s:BufSelect(line) abort
    let l:bufnr = split(a:line, ':')[0]
    execute 'buffer ' . l:bufnr
endfunction

" Fuzzy search open buffers
function! s:FzfBuffers() abort
    let l:bufs = filter(range(1, bufnr('$')), 'buflisted(v:val)')
    let l:lines = []
    for l:buf in l:bufs
        let l:name = bufname(l:buf)
        let l:name = empty(l:name) ? '[No Name]' : l:name
        let l:modified = getbufvar(l:buf, '&modified') ? ' *' : ''
        call add(l:lines, printf('%d: %s%s', l:buf, l:name, l:modified))
    endfor
    call fzf#run(fzf#wrap({
        \ 'source': l:lines,
        \ 'sink': function('s:BufSelect'),
        \ 'options': '--prompt="Buffers> "'
        \ }))
endfunction

" Helper for Ripgrep selection callback
function! s:GrepSelect(line) abort
    let l:parts = split(a:line, ':')
    if len(l:parts) >= 3
        execute 'edit +' . l:parts[1] . ' ' . fnameescape(l:parts[0])
        execute 'normal! ' . l:parts[2] . '|'
    endif
endfunction

" Fuzzy search text using Ripgrep (opens match at exact line and column)
function! s:FzfGrep() abort
    let l:cmd = 'rg --column --line-number --no-heading --color=always --smart-case ""'
    call fzf#run(fzf#wrap({
        \ 'source': l:cmd,
        \ 'sink': function('s:GrepSelect'),
        \ 'options': '--ansi --delimiter : --nth 4.. --prompt="Grep> "'
        \ }))
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

" Lightweight Autopairs
function! s:ClosePair(char) abort
    if getline('.')[col('.') - 1] == a:char
        return "\<Right>"
    else
        return a:char
    endif
endfunction

function! s:CloseQuote(char) abort
    let l:col = col('.')
    let l:line = getline('.')
    let l:next_char = l:line[l:col - 1]

    if l:next_char == a:char
        return "\<Right>"
    endif

    " Special case for single quote: don't pair if preceded by a letter/number
    if a:char ==# "'" && l:col > 1 && l:line[l:col - 2] =~# '[a-zA-Z0-9]'
        return "'"
    endif

    return a:char . a:char . "\<Left>"
endfunction

function! s:BackspacePair() abort
    let l:col = col('.')
    let l:line = getline('.')
    if l:col > 1
        let l:prev_char = l:line[l:col - 2]
        let l:next_char = l:line[l:col - 1]
        let l:pairs = {'(': ')', '[': ']', '{': '}', '"': '"', "'": "'", '`': '`'}
        if has_key(l:pairs, l:prev_char) && l:pairs[l:prev_char] == l:next_char
            return "\<BS>\<Delete>"
        endif
    endif
    return "\<BS>"
endfunction

" Set Netrw bindings
augroup NetrwCustom
    autocmd!
    autocmd FileType netrw call NetrwSettings()
augroup END

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

" Keybindings
let mapleader = ' '
inoremap jj <Esc>

" auto-close pairs
inoremap ( ()<Left>
inoremap [ []<Left>
inoremap { {}<Left>
inoremap <expr> ) <SID>ClosePair(')')
inoremap <expr> ] <SID>ClosePair(']')
inoremap <expr> } <SID>ClosePair('}')
inoremap <expr> " <SID>CloseQuote('"')
inoremap <expr> ' <SID>CloseQuote("'")
inoremap <expr> ` <SID>CloseQuote('`')
inoremap <expr> <BS> <SID>BackspacePair()

" Centered search result scrolling
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
nnoremap <expr> n (v:searchforward ? 'nzzzv' : 'Nzzzv')
nnoremap <expr> N (v:searchforward ? 'Nzzzv' : 'nzzzv')

" Blackhole deletes (prevent character deletions from polluting clipboard)
nnoremap x "_x
vnoremap x "_x
nnoremap X "_D
vnoremap X "_d

" Visual overwrite paste (prevent visual paste from replacing default register)
vnoremap p "_dP

" Persist visual selection when indenting
vnoremap < <gv
vnoremap > >gv

" Math increments (matches Neovim)
nnoremap - <C-x>
nnoremap = <C-a>

nmap Q :qa!<CR>
nmap <leader>e :Lexplore<CR>

" Fuzzy search maps matching pickme.nvim / Seeker
nnoremap <leader><space> :call fzf#run(fzf#wrap({'options': '--multi'}))<CR>
nnoremap <leader>fa :call fzf#run(fzf#wrap({'options': '--multi'}))<CR>
nnoremap <leader>ff :call fzf#run(fzf#wrap({'options': '--multi'}))<CR>
nnoremap <leader>,  :call <SID>FzfBuffers()<CR>
nnoremap <leader>fb :call <SID>FzfBuffers()<CR>
nnoremap <leader>fg :call <SID>FzfGrep()<CR>
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
