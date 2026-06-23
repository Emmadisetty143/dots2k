set nocompatible   " Disable vi compatibility
set noloadplugins  " Disable automatic loading of all plugins on startup
set encoding=utf-8 " Use UTF-8
set showmatch      " Show matching brackets
set ignorecase     " Do case insensitive matching
set incsearch      " Show partial matches for a search phrase
set number         " Show numbers
set relativenumber " Show relative numbers
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
set scrolloff=8    " Scroll offset
set sidescrolloff=5
set autoread       " Reload files on change
set smartcase      " Case-sensitive search if capital letter is typed
set confirm        " Ask to save changes on exiting modified buffer
set breakindent    " Wrapped lines preserve indentation
set whichwrap+=<,>,h,l,[,] " Allow keys to wrap lines
set iskeyword+=-   " Treat dash-separated words as a single word
set tabpagemax=50  " More tabs
set history=1000   " More history
set viminfo^=!     " Better viminfo
set backspace=indent,eol,start " Delete everything
set formatoptions+=j " Delete comment character when joining
set listchars=tab:,nbsp:_,trail:,extends:>,precedes:<
set list           " Highlight non whitespace characters
set fillchars=eob:\  " Clean trailing tildes
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
set clipboard=unnamedplus " Copy Paste from System Clipboard
set statusline=\ %{StatuslineMode()}\ \ \ \ %l:%c\ \ \ \ %p%%\ \ \ \ %f\ %m\ %r%=%{&filetype}\ \ \ \ %{StatuslineFileSize()}\ \ \ \ %{&fileencoding?&fileencoding:&encoding}
set spelllang=en " Set spell check language to en (disabled by default)
syntax enable      " Turn on syntax highlighting

let g:fzf_layout = { 'window': { 'width': 0.9, 'height': 0.8 } } " FZF Floating Window Layout Configuration

" Auto-create parent directory if it does not exist
function! s:AutoCreateDir() abort
    let l:dir = expand('<afile>:p:h')
    if !isdirectory(l:dir)
        call mkdir(l:dir, 'p')
    endif
endfunction

augroup GeneralAutocmds
    autocmd!
    " Go to last position when reopening a file
    autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
    " Remove trailing whitespace on write
    autocmd BufWritePre * %s/\s\+$//e
    " Close help, quickfix, and man buffers with 'q'
    autocmd FileType help,qf,man nnoremap <buffer><silent> q :close<CR>
    " Automatically check and reload files modified outside of Vim
    autocmd FocusGained * if mode() !~ '\v(c|t)' | silent! checktime | endif
    autocmd BufEnter * if &buftype == '' && filereadable(expand('%')) && mode() !~ '\v(c|t)' | silent! checktime % | endif
    " Resize splits if window got resized
    autocmd VimResized * tabdo wincmd =
    " Wrap and check spell in text filetypes
    autocmd FileType gitcommit,markdown setlocal wrap spell
    " Disable formatoptions comment continuation on new lines
    autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
    " Auto-create directory when saving a file
    autocmd BufWritePre * call s:AutoCreateDir()
augroup END

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

" Helper for Ripgrep selection callback (safe parsing for colons and drives)
function! s:GrepSelect(line) abort
    let l:match = matchlist(a:line, '^\(.\{-}\):\(\d\+\):\(\d\+\):\(.*\)$')
    if !empty(l:match)
        let l:file = l:match[1]
        let l:lnum = l:match[2]
        let l:col = l:match[3]
    else
        let l:match = matchlist(a:line, '^\(.\{-}\):\(\d\+\):\(.*\)$')
        if !empty(l:match)
            let l:file = l:match[1]
            let l:lnum = l:match[2]
            let l:col = 1
        else
            return
        endif
    endif
    execute 'edit +' . l:lnum . ' ' . fnameescape(l:file)
    execute 'normal! ' . l:col . '|'
endfunction

" Unified Ripgrep search command flags
let s:rg_base = 'rg --column --line-number --no-heading --color=always --smart-case --hidden --glob "!.git/*"'

" Fuzzy search text using Ripgrep (including hidden files, excluding .git)
function! s:FzfGrep() abort
    call fzf#run(fzf#wrap({
        \ 'source': s:rg_base . ' ""',
        \ 'sink': function('s:GrepSelect'),
        \ 'options': '--ansi --delimiter : --nth 4.. --prompt="Grep> "'
        \ }))
endfunction

" Fuzzy search word under cursor
function! s:FzfGrepWord() abort
    let l:word = expand('<cword>')
    if empty(l:word) | return | endif
    call fzf#run(fzf#wrap({
        \ 'source': s:rg_base . ' ' . shellescape(l:word),
        \ 'sink': function('s:GrepSelect'),
        \ 'options': '--ansi --delimiter : --nth 4.. --prompt="GrepWord: ' . l:word . '> "'
        \ }))
endfunction

" Fuzzy search all files in project directory
function! s:FzfAllFiles() abort
    call fzf#run(fzf#wrap({
        \ 'options': '--prompt="Files> "'
        \ }))
endfunction

" Fuzzy search git files (using git ls-files)
function! s:FzfGitFiles() abort
    if isdirectory('.git') || system('git rev-parse --is-inside-work-tree') =~# 'true'
        call fzf#run(fzf#wrap({
            \ 'source': 'git ls-files --exclude-standard --cached --others',
            \ 'options': '--prompt="GitFiles> "'
            \ }))
    else
        call s:FzfAllFiles()
    endif
endfunction

" Fuzzy search old files history
function! s:FzfHistory() abort
    call fzf#run(fzf#wrap({
        \ 'source': filter(copy(v:oldfiles), 'filereadable(expand(v:val))'),
        \ 'options': '--prompt="History> "'
        \ }))
endfunction

" Shared helper for buffer line searching
function! s:FzfLinesHelper(bufs, prompt) abort
    let l:lines = []
    for l:buf in a:bufs
        let l:bufname = bufname(l:buf)
        let l:bufname = empty(l:bufname) ? '[No Name]' : l:bufname
        let l:content = getbufline(l:buf, 1, '$')
        let l:idx = 1
        for l:line in l:content
            call add(l:lines, printf('%s:%d:%s', l:bufname, l:idx, l:line))
            let l:idx += 1
        endfor
    endfor
    call fzf#run(fzf#wrap({
        \ 'source': l:lines,
        \ 'sink': function('s:GrepSelect'),
        \ 'options': '--ansi --delimiter : --nth 3.. --prompt="' . a:prompt . '> "'
        \ }))
endfunction

" Fuzzy search lines in all open buffers
function! s:FzfLines() abort
    call s:FzfLinesHelper(filter(range(1, bufnr('$')), 'buflisted(v:val) && bufloaded(v:val)'), 'Lines')
endfunction

" Fuzzy search lines in current buffer
function! s:FzfBLines() abort
    call s:FzfLinesHelper([bufnr('%')], 'BLines')
endfunction

" Helper to get current mode for statusline
function! StatuslineMode() abort
    return get({'n':'N','v':'V','V':'VL',"\<C-v>":'VB','i':'I','R':'R','c':'C','t':'T'}, mode(), mode())
endfunction

" Helper to get current file size for statusline
function! StatuslineFileSize() abort
    let l:b = getfsize(expand('%:p'))
    return l:b <= 0 ? '' : l:b < 1024 ? l:b.'B' : l:b < 1048576 ? printf('%.1fKiB', l:b/1024.0) : printf('%.1fMiB', l:b/1048576.0)
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

" Project-wide search and replace via Ripgrep and Quickfix
function! s:GetDelimiter(find, replace) abort
    let l:delimiters = ['/', '#', '@', '_', '~', ';']
    for l:d in l:delimiters
        if stridx(a:find, l:d) == -1 && stridx(a:replace, l:d) == -1
            return l:d
        endif
    endfor
    return '/'
endfunction

function! s:Replace(query) abort
    let l:find = a:query
    if empty(l:find)
        let l:find = input('Find: ')
    endif
    if empty(l:find)
        return
    endif

    let l:replace = input('Replace with: ')

    " Populate quickfix list using Ripgrep
    let l:grep_cmd = 'rg --vimgrep --smart-case ' . shellescape(l:find)
    let l:output = system(l:grep_cmd)
    if v:shell_error != 0 || empty(l:output)
        echohl WarningMsg | echo 'No matches found for: ' . l:find | echohl None
        return
    endif

    " Load results into quickfix
    let l:lines = split(l:output, "\n")
    call setqflist([], 'r', {'title': 'Search: ' . l:find, 'lines': l:lines})

    let l:original_buf = bufnr('%')
    copen

    " Pick a safe delimiter for the substitution command
    let l:d = s:GetDelimiter(l:find, l:replace)

    " Prompt user for confirmation mode
    let l:choice = confirm('Replace all occurrences?', "&Yes\n&Confirm each\n&Cancel", 1)
    if l:choice == 1
        " Replace all instantly across all files and update
        let l:cmd = 'cfdo %s' . l:d . l:find . l:d . l:replace . l:d . 'g | update'
        try
            execute l:cmd
            execute 'buffer ' . l:original_buf
            echo 'Replaced all occurrences of "' . l:find . '" with "' . l:replace . '"'
        catch
            echohl ErrorMsg | echo 'Replacement failed: ' . v:exception | echohl None
        endtry
    elseif l:choice == 2
        " Pre-populate the command line for manual step-by-step confirmation
        let l:replace_cmd = 'cfdo %s' . l:d . l:find . l:d . l:replace . l:d . 'gc | update'
        call feedkeys(':' . l:replace_cmd, 'n')
    endif
endfunction

command! -nargs=? Replace call s:Replace(<q-args>)

" Copy text to clipboard (works on Wayland/X11 with native +clipboard, or WSL via win32yank)
function! s:CopyToClipboard(text) abort
    if executable('win32yank.exe') | call system('win32yank.exe -i', a:text)
    elseif has('clipboard')        | let @+ = a:text
    else                           | let @" = a:text | endif
endfunction

" Copy GitHub URL for the current line or visual selection
function! s:CopyGitUrl(line1, line2) abort
    let l:relative_file = expand('%:.')
    if empty(l:relative_file) | return | endif

    let l:repo_url = system('git config --get remote.origin.url')
    let l:repo_url = substitute(l:repo_url, '\n$', '', '')
    let l:repo_url = substitute(l:repo_url, '\.git$', '', '')
    if empty(l:repo_url)
        echohl WarningMsg | echo 'Not a git repository' | echohl None
        return
    endif

    " Convert SSH git@github.com:user/repo to HTTPS URL (GitHub only)
    let l:repo_url = substitute(l:repo_url, 'git@github\.com:', 'https://github.com/', '')
    let l:repo_url = substitute(l:repo_url, 'ssh://git@github\.com/', 'https://github.com/', '')

    let l:branch = system('git branch --show-current')
    let l:branch = substitute(l:branch, '\n$', '', '')
    if empty(l:branch)
        let l:branch = system('git rev-parse --short HEAD')
        let l:branch = substitute(l:branch, '\n$', '', '')
    endif

    let l:url = printf('%s/blob/%s/%s#L%d', l:repo_url, l:branch, l:relative_file, a:line1)
    if a:line1 != a:line2
        let l:url = printf('%s-L%d', l:url, a:line2)
    endif

    call s:CopyToClipboard(l:url)
    echo 'Copied Git URL to clipboard: ' . l:url
endfunction

command! -range CopyGitUrl call s:CopyGitUrl(<line1>, <line2>)

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

" Seamless Vim/Tmux Split Navigation
function! s:TmuxNavigate(direction) abort
    let l:winnr = winnr()
    execute 'wincmd ' . a:direction
    if l:winnr == winnr() && exists('$TMUX')
        let l:tmux_dir = {'h': 'L', 'j': 'D', 'k': 'U', 'l': 'R'}
        call system('tmux select-pane -' . l:tmux_dir[a:direction])
    endif
endfunction

" Netrw settings
let g:netrw_liststyle = 3
let g:netrw_banner = 0  " Hide help banner to match nvim-tree
let g:netrw_winsize = 25 " Match default Neovim explorer width
let g:netrw_browse_split = 4 " Open files in previous active window (retains sidebar)
let g:netrw_altv = 1         " Open vertical splits on the right
let g:netrw_list_hide = ''   " Show hidden files (dotfiles) by default

augroup NetrwCustom
    autocmd!
    autocmd FileType netrw call NetrwSettings()
augroup END

function! NetrwSettings() abort
    nnoremap <buffer> a %
    nnoremap <buffer> A d
    nnoremap <buffer> r R
    nnoremap <buffer> d D
    nnoremap <buffer> H gh
    nnoremap <buffer> q :Lexplore<CR>
    nnoremap <buffer> l <CR>
endfunction

" Keybindings
let mapleader = ' '
inoremap jj <Esc>
nnoremap <leader>ee :Lexplore<CR>
nnoremap H :bprevious<CR>
nnoremap L :bnext<CR>
nnoremap <leader>rc :source $MYVIMRC<CR>:echo "Vimrc sourced!"<CR>
nnoremap <leader>s :setlocal spell!<CR>
nnoremap <leader>t :term<CR>
nnoremap <leader>ww :w<CR>
nnoremap <silent> <Esc> :nohlsearch<CR><Esc>

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

" Easy home-row line start and end navigation
nnoremap gh ^
vnoremap gh ^
nnoremap gl $
vnoremap gl $

" Keep cursor position when joining lines
nnoremap J mzJ`z

" Drag Visual selections
vnoremap K xkP`[V`]
vnoremap J xp`[V`]
vnoremap L >gv
vnoremap H <gv

" Insert blank lines above/below cursor without moving cursor
nnoremap <silent> [<space> :<C-u>put! =repeat(nr2char(10), v:count1)<bar>']+1<CR>
nnoremap <silent> ]<space> :<C-u>put =repeat(nr2char(10), v:count1)<bar>'[-1<CR>

" Bracket navigation (Quickfix, Location list, Buffer, Jump list, and Windows)
nnoremap <silent> [q :cprev<CR>
nnoremap <silent> ]q :cnext<CR>
nnoremap <silent> [Q :cfirst<CR>
nnoremap <silent> ]Q :clast<CR>
nnoremap <silent> [l :lprev<CR>
nnoremap <silent> ]l :lnext<CR>
nnoremap <silent> [L :lfirst<CR>
nnoremap <silent> ]L :llast<CR>
nnoremap <silent> [b :bprevious<CR>
nnoremap <silent> ]b :bnext<CR>
nnoremap <silent> [B :bfirst<CR>
nnoremap <silent> ]B :blast<CR>
nnoremap <silent> [j <C-o>
nnoremap <silent> ]j <C-i>
nnoremap <silent> [w <C-w>p
nnoremap <silent> ]w <C-w>w

" Math increments (matches Neovim)
nnoremap - <C-x>
nnoremap = <C-a>

" Fuzzy search maps matching pickme.nvim / Seeker
nnoremap <leader>,  :call <SID>FzfBuffers()<CR>
nnoremap <leader>/  :history /<CR>
nnoremap <leader>:  :history :<CR>
nnoremap <leader><space> :FZF<CR>
nnoremap <leader>fa :call <SID>FzfAllFiles()<CR>
nnoremap <leader>fb :call <SID>FzfBuffers()<CR>
nnoremap <leader>ff :call <SID>FzfGitFiles()<CR>
nnoremap <leader>fg :call <SID>FzfGrep()<CR>
nnoremap <leader>fl :lopen<CR>
nnoremap <leader>fo :call <SID>FzfLines()<CR>
nnoremap <leader>fq :copen<CR>
nnoremap <leader>fr :call <SID>FzfHistory()<CR>
nnoremap <leader>fs :call <SID>FzfBLines()<CR>
nnoremap <leader>ft :command<CR>
nnoremap <leader>fu :undolist<CR>
nnoremap <leader>fw :call <SID>FzfGrepWord()<CR>

" Replace / substitution helper mappings
nnoremap <leader>ra :Replace<CR>
nnoremap <leader>rb :%s///gc<Left><Left><Left><Left>
nnoremap <leader>rs :%s/\<<C-r><C-w>\>/\<C-r>\<C-w>/gI<Left><Left><Left>
nnoremap <leader>rw :Replace <C-r><C-w><CR>

" Git Search Keymaps (Lazygit & Shell Git Integration)
nnoremap <leader>gg :silent !lazygit<CR>:redraw!<CR>
nnoremap <C-g> :silent !lazygit<CR>:redraw!<CR>
nnoremap <silent> <leader>yL :call <SID>CopyToClipboard(expand('%:p') . ':' . line('.'))<CR>
nnoremap <silent> <leader>yP :call <SID>CopyToClipboard(expand('%:p'))<CR>
nnoremap <silent> <leader>ya :%y+<CR>
nnoremap <silent> <leader>yf :call <SID>CopyToClipboard(expand('%:t'))<CR>
nnoremap <silent> <leader>yg :CopyGitUrl<CR>
vnoremap <silent> <leader>yg :CopyGitUrl<CR>
nnoremap <silent> <leader>yl :call <SID>CopyToClipboard(expand('%') . ':' . line('.'))<CR>
nnoremap <silent> <leader>yp :call <SID>CopyToClipboard(expand('%'))<CR>

" Vim Options & Help Inspections
nnoremap <leader>oa :autocmd<CR>
nnoremap <leader>oc :history :<CR>
nnoremap <leader>oC :colorscheme <Tab>
nnoremap <leader>od :help
nnoremap <leader>of :marks<CR>
nnoremap <leader>og :command<CR>
nnoremap <leader>oh :highlight<CR>
nnoremap <leader>oj :jumps<CR>
nnoremap <leader>ok :map<CR>
nnoremap <leader>om :Man
nnoremap <leader>on :messages<CR>
nnoremap <leader>oo :set<CR>
nnoremap <leader>os :history /<CR>

" Edit Config Files Mappings
nnoremap <leader>eca :call fzf#run(fzf#wrap({'dir': expand('~/.config'), 'options': '--prompt="Config> "'}))<CR>
nnoremap <leader>ecc :edit $MYVIMRC<CR>

" Split Creation and Navigation
nnoremap <leader>s\ <C-w>v
nnoremap <leader>s/ <C-w>s
nnoremap <leader>sa :split<CR>
nnoremap <leader>ss :vsplit<CR>
nnoremap <leader>sh <C-w>h
nnoremap <leader>sj <C-w>j
nnoremap <leader>sk <C-w>k
nnoremap <leader>sl <C-w>l
nnoremap <leader>s` <C-w>p
nnoremap <leader>sc :tabclose<CR>
nnoremap <leader>sf :tabfirst<CR>

" Seamless Vim/Tmux Navigation
nnoremap <silent> <C-h> :call <SID>TmuxNavigate('h')<CR>
nnoremap <silent> <C-j> :call <SID>TmuxNavigate('j')<CR>
nnoremap <silent> <C-k> :call <SID>TmuxNavigate('k')<CR>
nnoremap <silent> <C-l> :call <SID>TmuxNavigate('l')<CR>

" Split Window Resizing
nnoremap <leader>sH :vertical resize -10<CR>
nnoremap <leader>sJ :resize -10<CR>
nnoremap <leader>sK :resize +10<CR>
nnoremap <leader>sL :vertical resize +10<CR>

" Buffer Control & Quit Operations
nnoremap Q :qa!<CR>
nnoremap <leader>x  :x<CR>
nnoremap <leader>qa :qall<CR>
nnoremap <leader>qb :bw<CR>
nnoremap <leader>qf :qall!<CR>
nnoremap <leader>qq :q<CR>
nnoremap <leader>qs <C-w>c
nnoremap <leader>qw :wq<CR>
nnoremap <leader>ea :b#<CR>
nnoremap <leader>en :enew<CR>
nnoremap <leader>qo :%bdelete\|b#\|bdelete#<CR>
nnoremap <leader>qd :b#\|bd#<CR>

" tmux true color fix
if (has("termguicolors"))
    set termguicolors
endif

augroup ColorOverrides
    autocmd!
    " Always use terminal background
    autocmd ColorScheme * highlight! Normal ctermbg=NONE guibg=NONE
    autocmd ColorScheme * highlight! Terminal ctermbg=NONE guibg=NONE

    " Tone down cursor line, status bar, and tabline highlight colors globally
    autocmd ColorScheme * highlight CursorLine cterm=NONE ctermbg=235 guibg=#222530
    autocmd ColorScheme * highlight StatusLine cterm=NONE ctermfg=14 ctermbg=0 guifg=#89b4fa guibg=#000000
    autocmd ColorScheme * highlight StatusLineNC cterm=NONE ctermfg=8 ctermbg=0 guifg=#585b70 guibg=#000000
    autocmd ColorScheme * highlight TabLineSel cterm=NONE ctermfg=15 ctermbg=235 guifg=#ffffff guibg=#252535
    autocmd ColorScheme * highlight TabLine cterm=NONE ctermfg=244 ctermbg=234 guifg=#a6adc8 guibg=#181825
    autocmd ColorScheme * highlight TabLineFill cterm=NONE ctermbg=0 guibg=#000000
    autocmd ColorScheme * highlight MsgArea ctermfg=15 guifg=#ffffff
augroup END

augroup StatuslineColors
    autocmd!
    autocmd ModeChanged *:i highlight StatusLine ctermfg=10 guifg=#a6e3a1
    autocmd ModeChanged *:R highlight StatusLine ctermfg=10 guifg=#a6e3a1
    autocmd ModeChanged *:v highlight StatusLine ctermfg=3 guifg=#f9e2af
    autocmd ModeChanged *:V highlight StatusLine ctermfg=3 guifg=#f9e2af
    execute "autocmd ModeChanged *:\<C-v> highlight StatusLine ctermfg=3 guifg=#f9e2af"
    autocmd ModeChanged *:t highlight StatusLine ctermfg=9 guifg=#f38ba8
    autocmd ModeChanged *:n highlight StatusLine ctermfg=14 guifg=#89b4fa
augroup END

" Load colorscheme with fallback to built-in 'slate'
try
    colorscheme catppuccin
catch /^Vim\%((\a\+)\)\=:E185/
    colorscheme slate
endtry

" Manually load required plugins since noloadplugins is set
silent! runtime plugin/matchparen.vim  " Highlight matching parentheses
silent! packadd! matchit               " Extended % matching for HTML tags, etc.
silent! runtime plugin/spellfile.vim   " Auto-download missing spellfiles
silent! runtime ftplugin/man.vim       " Enable :Man command to view man pages
silent! runtime plugin/logiPat.vim     " Boolean logical search patterns (:LogiPat)
silent! runtime plugin/fzf.vim         " Fuzzy finder integration
silent! packadd netrw                  " File explorer
