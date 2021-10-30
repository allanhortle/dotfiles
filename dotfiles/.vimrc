"
" Plugins
"
set nocompatible
if empty(glob('~/.vim/autoload/plug.vim'))
    silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    autocmd VimEnter * PlugInstall | source $MYVIMRC
endif
call plug#begin('~/.vim/plugged')

Plug '/usr/local/opt/fzf' | Plug 'junegunn/fzf.vim'
Plug 'airblade/vim-gitgutter'
Plug 'benmills/vimux'
Plug 'docunext/closetag.vim'
Plug 'dyng/ctrlsf.vim'
Plug 'iberianpig/tig-explorer.vim'
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' } 
Plug 'junegunn/goyo.vim'
Plug 'junegunn/vim-peekaboo'
Plug 'mattn/emmet-vim'
Plug 'mbbill/undotree'
Plug 'mhinz/vim-startify'
Plug 'mzlogin/vim-markdown-toc'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'scrooloose/nerdcommenter'
Plug 'scrooloose/nerdtree'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-markdown'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'

" Syntax
Plug 'cakebaker/scss-syntax.vim'
Plug 'calviken/vim-gdscript3'
Plug 'editorconfig/editorconfig-vim'
Plug 'jason0x43/vim-js-indent'
Plug 'jparise/vim-graphql'
Plug 'maxmellon/vim-jsx-pretty'
Plug 'pangloss/vim-javascript'
Plug 'peitalin/vim-jsx-typescript'
call plug#end() 


"
" General Vim Settings
"
set autoindent                  " always set auto-indenting on
set background=dark
set backspace=indent,eol,start  " allow backspacing over everything in insert mode
set complete=.,w,b,u,i          " turn off tab completion for tags
set copyindent                  " copy the previous indentation on auto-indenting
set encoding=utf8
set expandtab
set foldlevel=20
set hidden
set hlsearch
set ignorecase                  " ignore case when searching
set incsearch                   " show search matches as you type
set lazyredraw                  " dont redraw in the middle of a macro
set mouse=a
set nowrap
set number                      " always show line numbers
set rtp+=/usr/local/opt/fzf
set shiftround                  " use multiple of shiftwidth when indenting with '<' and '>'
set shiftwidth=4                " number of spaces to use for auto-indenting
set signcolumn=number
set showmatch                   " set show matching 
set showcmd
set smartcase                   " ignore case if search pattern is all lower-case case-sensitive otherwise
set smarttab                    " insert tabs on the start of a line according to shiftwidth, not tabstop
set softtabstop=4
set splitright                  " set vertical splits to the right
set synmaxcol=500               " stop checking syntax regexes after 500, hopefully prettier makes this fine
set fillchars=vert:\            " set empty vert chartacter
set suffixesadd=.jsx,.md,.js
set t_Co=256
set t_BE=
set tabstop=4                   " a tab is four spaces
set timeoutlen=1000 ttimeoutlen=0
set updatetime=250
set wildmenu
set wildmode=longest:full,full
set numberwidth=1               " make line numbers closer to ~
set colorcolumn=100
set writebackup                 " protect against crash-during-write
set nobackup                    " but do not persist backup after successful write
set backupcopy=auto             " use rename-and-write-new method whenever safe
set undofile                    " persist the undo tree for each file
set noswapfile                  " dont have swap files, they are lame.

" Vim only settings
if !has('nvim')
    set ttymouse=sgr                " make the mouse work after line 223
    set backupdir^=~/.vim/backup//  " keep all the backup files in .vim
    set undodir^=~/.vim/undo//
endif

" Cursor types
let &t_EI = "\033[2 q" " NORMAL  █
let &t_SI = "\033[5 q" " INSERT  |
let &t_SR = "\033[3 q" " REPLACE _

" plain text type file options
augroup WritingFiles
    autocmd!
    autocmd FileType markdown set wrap
    autocmd FileType markdown setlocal spell
    autocmd FileType gitcommit setlocal spell
augroup END

" Disable auto commenting
autocmd FileType * setlocal formatoptions-=c formatoptions-=r formatoptions-=o
filetype plugin on


"
" Plugin Settings
"

" markdown
let g:markdown_fold_style = 'nested'
let g:markdown_fenced_languages = ['javascript', 'typescript']

" emmet
"let g:user_emmet_expandabbr_key='<Tab>'
"imap <expr> <tab> emmet#expandAbbrIntelligent("\<tab>")

" Goyo
function! s:goyo_enter()
    set linebreak!
endfunction

function! s:goyo_leave()
    set linebreak!
endfunction

autocmd! User GoyoEnter call <SID>goyo_enter()
autocmd! User GoyoLeave call <SID>goyo_leave()

" FZF
let g:fzf_preview_window = ''
let g:fzf_layout = { 'up': '50%' }

" Startify
let g:startify_change_to_dir = 0
let g:startify_lists = [
    \ { 'type': 'dir',       'header': ['   MRU '. getcwd()] },
    \ { 'type': 'files',     'header': ['   MRU']            },
    \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      },
    \ { 'type': 'commands',  'header': ['   Commands']       },
    \ ]

" ctrlsf
let g:ctrlsf_auto_focus = { "at": "start" }
let g:ctrlsf_populate_qflist = 1


"
" Coc
" 

" Extensions
let g:coc_global_extensions = [
    \ 'coc-tsserver',
    \ 'coc-json',
    \ 'coc-explorer',
    \ 'coc-vimlsp',
    \ 'coc-styled-components'
\ ]

if isdirectory('./node_modules') && isdirectory('./node_modules/prettier')
    let g:coc_global_extensions += ['coc-prettier']
endif

if isdirectory('./node_modules') && isdirectory('./node_modules/eslint')
    let g:coc_global_extensions += ['coc-eslint']
endif

" tab/shift-tab navigate through Pmenu
function! s:check_back_space() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
inoremap <silent><expr> <TAB> pumvisible() ? "\<C-n>" : <SID>check_back_space() ? "\<TAB>" : coc#refresh()
inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"


" Coc Mappings
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)
nmap <leader>rn <Plug>(coc-rename)
nnoremap <silent> K :call CocAction('doHover')<CR>
nnoremap <C-O> :CocCommand explorer<CR>
nnoremap <C-L> :execute 'CocCommand explorer ' . expand('%:h')<CR>


"
" Keyboard Mapping
"
nmap <F1> :echo expand('%:p')<cr>
set pastetoggle=<F2>
map <F3> :set wrap!<CR>:set linebreak!<CR>
map <F6> :setlocal spell! spelllang=en_au<CR>
map <F7> :Goyo<CR>
map <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<' . synIDattr(synID(line("."),col("."),0),"name") . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

" Make help vertical
cnoreabbrev <expr> help ((getcmdtype() is# ':'    && getcmdline() is# 'help')?('vert help'):('help'))
cnoreabbrev <expr> h ((getcmdtype() is# ':'    && getcmdline() is# 'h')?('vert help'):('h'))

" Wrapped navigation
nnoremap j gj
nnoremap k gk
nnoremap gj j
nnoremap gk k

nnoremap Y y$
nnoremap <Leader><Leader> :Buffers<CR>
nnoremap <Space> .
nnoremap <MiddleMouse> :call CocAction('doHover')<CR>
nnoremap <C-p> :Files<CR>
nnoremap <expr> <C-p> (expand('%') =~ 'NERD_tree' ? ":NERDTreeToggle\<CR>" : '').":Files\<cr>"
nmap <C-f> <Plug>CtrlSFPrompt
nnoremap <CR> :noh<CR><CR>
nnoremap <Leader>h :Startify<CR>
nnoremap <Leader>b :bp<CR>
nnoremap <Leader>e :CocList --normal -A diagnostics<CR>
nnoremap <Leader>a :CocAction<CR>
nnoremap <Leader>f :bn<CR>
nnoremap <Leader>q :bp \|bw #<CR>
nnoremap <Leader>s :Startify<CR>
nnoremap <Leader>r :source $MYVIMRC<CR>
nnoremap <Leader>u :UndotreeToggle<CR>
nnoremap <Leader>d1 :diffget LOCAL<CR>
nnoremap <Leader>d2 :diffget BASE<CR>
nnoremap <Leader>d3 :diffget REMOTE<CR>

nnoremap Q @@
vnoremap Y "*y
nnoremap + <C-a>
nnoremap - <C-x>

" tig
nnoremap <Leader>tt :Tig<CR>
nnoremap <Leader>ts :TigStatus<CR>
nnoremap <Leader>th :TigOpenCurrentFile<CR>
nnoremap <Leader>tb :TigBlame<CR>

" windows
nnoremap <Leader><Tab> <C-W>w

" window/buffer splitting
nnoremap <leader>s<left>   :leftabove  vnew<CR>
nnoremap <leader>s<right>  :rightbelow vnew<CR>
nnoremap <leader>s<up>     :leftabove  new<CR>
nnoremap <leader>s<down>   :rightbelow new<CR>

" Commands
command! -bang Q q<bang>
command! -bang Qa qa<bang>
command! -bang QA qa<bang>
command! -bang W w<bang>
command! -bang Wa wa<bang>
command! -bang WA wa<bang>
command! -bang Wq wq<bang>
command! -bang WQ wq<bang>
command! -bang Wqa wqa<bang>
command! -bang WQa wqa<bang>
command! -bang WQA wqa<bang>

" nops
noremap <Up> <nop>
noremap <Down> <nop>
noremap <Left> <nop>
noremap <Right> <nop>
noremap <BS> <nop>
noremap <TAB> <nop>
nnoremap q: <nop>


"
" Syntax Highlighting
"

" jsx files
augroup filetypedetect
    au BufRead,BufNewFile *.jsx set filetype=javascript
    au BufRead,BufNewFile *.tsx set filetype=typescript.tsx
augroup END

syntax reset
syntax on
if &diff
    syntax off
endif
colorscheme puffin


"
" statusline
"
set noshowmode " dont show --insert--
set laststatus=2 " always visible
hi StatusLine ctermbg=black ctermfg=white cterm=none 
hi StatusLineNC ctermbg=black cterm=NONE
hi NormalColor ctermbg=blue ctermfg=black
hi InsertColor ctermbg=green ctermfg=black
hi OtherColor ctermbg=yellow ctermfg=black
hi ErrorColor ctermbg=red ctermfg=black
hi VisualColor ctermbg=magenta ctermfg=black
hi InactiveColor ctermbg=grey ctermfg=black

function! CurrentMode() abort
    let l:currentmode = {
        \ 'n'      : 'normal',
        \ 'no'     : 'normal op',
        \ 'v'      : 'visual',
        \ 'V'      : 'vline',
        \ 's'      : 'select',
        \ 'S'      : 'sline',
        \ '\<C-S>' : 'sblock',
        \ 'i'      : 'insert',
        \ 'R'      : 'replace',
        \ 'Rv'     : 'vreplace',
        \ 'c'      : 'command',
        \ 'cv'     : 'vim ex',
        \ 'ce'     : 'ex',
        \ 'r'      : 'prompt',
        \ 'rm'     : 'more',
        \ 'r?'     : 'confirm',
        \ '!'      : 'shell',
        \ 't'      : 'terminal'
    \}
    let l:modecurrent = mode()
    let l:modelist = get(l:currentmode, l:modecurrent, 'vblock')
    let l:current_status_mode = l:modelist
    return l:current_status_mode
endfunction

function! StatusLineColor() 
    let l:mode = CurrentMode()
    let l:modecolors={
        \ 'normal': 'NormalColor',
        \ 'insert': 'InsertColor',
        \ 'visual': 'VisualColor',
        \ 'vblock': 'VisualColor',
        \ 'vline': 'VisualColor',
        \ 'command': 'OtherColor',
        \}

    let info = get(b:, 'coc_diagnostic_info', {})
    if get(info, 'error', 0) && l:mode == 'normal'
        return "%#ErrorColor#" 
    endif

    if g:actual_curwin != win_getid() 
        return "%#InactiveColor#" 
    endif
    return "%#" . get(l:modecolors, l:mode, 'StatusLine') . "#"
endfunction

function! StatusDiagnostic() abort
    let info = get(b:, 'coc_diagnostic_info', {})
    if empty(info) | return '' | endif
    let msgs = []
    if get(info, 'error', 0)
        call add(msgs, '!' . info['error'])
    endif
    if get(info, 'warning', 0)
        call add(msgs, '?' . info['warning'])
    endif
    return join(msgs, ' ')
endfunction

function! StatusLineContent()
  let statusline=""
  let statusline.=" %{CurrentMode()} "
  let statusline.=" %(%-0.75f %M%)"
  let statusline.=" %{StatusDiagnostic()}"
  let statusline.="%="
  let statusline.="%( %r%w%y%)"
  let statusline.=" %v:%l/%L "
  return statusline
endfunction

set statusline=
set statusline+=%{%StatusLineColor()%}
set statusline+=%{%StatusLineContent()%}

