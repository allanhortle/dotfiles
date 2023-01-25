
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
Plug 'beloglazov/vim-online-thesaurus'
Plug 'dhruvasagar/vim-zoom'
Plug 'docunext/closetag.vim'
Plug 'dyng/ctrlsf.vim'
Plug 'editorconfig/editorconfig-vim'
Plug 'iberianpig/tig-explorer.vim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'junegunn/goyo.vim'
Plug 'junegunn/vim-peekaboo'
Plug 'jxnblk/vim-mdx-js'
Plug 'mattn/emmet-vim'
Plug 'mbbill/undotree'
Plug 'mhinz/vim-startify'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'ruanyl/vim-gh-line'
Plug 'scrooloose/nerdcommenter'
Plug 'tpope/vim-abolish'
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-markdown'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-dadbod'
Plug 'tweekmonster/startuptime.vim'

" Neovim
Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
Plug 'nvim-treesitter/nvim-treesitter-context'
Plug 'nvim-treesitter/playground'
Plug 'David-Kunz/treesitter-unit'
call plug#end() 


"
" General Vim Settings
"
set autoindent                  " always set auto-indenting on
set background=dark
set backspace=indent,eol,start  " allow backspacing over everything in insert mode
set backupcopy=auto             " use rename-and-write-new method whenever safe
set colorcolumn=120
set complete=.,w,b,u,i          " turn off tab completion for tags
set copyindent                  " copy the previous indentation on auto-indenting
set cmdwinheight=32             " height of the command history window 
set encoding=utf8
set expandtab
set fillchars=vert:\            " set empty vert chartacter
set foldlevel=20
set hidden
set hlsearch
set ignorecase                  " ignore case when searching
set incsearch                   " show search matches as you type
set lazyredraw                  " dont redraw in the middle of a macro
set mouse=a
set nobackup                    " but do not persist backup after successful write
set noswapfile                  " dont have swap files, they are lame.
set nowrap
set number                      " always show line numbers
set numberwidth=1               " make line numbers closer to ~
set rtp+=/usr/local/opt/fzf
set shiftround                  " use multiple of shiftwidth when indenting with '<' and '>'
set shiftwidth=4                " number of spaces to use for auto-indenting
set showcmd
set showmatch                   " set show matching 
set signcolumn=number
set smartcase                   " ignore case if search pattern is all lower-case case-sensitive otherwise
set smarttab                    " insert tabs on the start of a line according to shiftwidth, not tabstop
set softtabstop=4
set splitbelow                 
set splitright                  
set spellsuggest=best,10
set suffixesadd=.jsx,.md,.js
set synmaxcol=500               " stop checking syntax regexes after 500, hopefully prettier makes this fine
set t_BE=
set t_Co=256
set tabstop=4                   " a tab is four spaces
set timeoutlen=1000 ttimeoutlen=0
set undofile                    " persist the undo tree for each file
set updatetime=100
set wildmenu
set wildmode=longest:full,full
set writebackup                 " protect against crash-during-write

" Vim only settings
if !has('nvim')
    set ttymouse=sgr                " make the mouse work after line 223
    set backupdir^=~/.vim/backup//  " keep all the backup files in .vim
    set undodir^=~/.vim/undo//
    colorscheme puffin
else 
    colorscheme ts-colors
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


" Make help vertical
augroup vimrc_help
  autocmd!
  autocmd BufEnter *.txt if &buftype == 'help' | wincmd L | endif
augroup END


"
" Plugin Settings
"

" nerdcommenter
let g:NERDCompactSexyComs = 1

" markdown
let g:markdown_fold_style = 'nested'
let g:markdown_fenced_languages = ['javascript', 'typescript']

" Goyo
function! s:goyo_enter()
    set linebreak!
endfunction

function! s:goyo_leave()
    set linebreak!
endfunction

autocmd! User GoyoEnter call <SID>goyo_enter()
autocmd! User GoyoLeave call <SID>goyo_leave()

" fzf
let g:fzf_preview_window = ''
let g:fzf_layout = { 'window': { 'width': 0.5, 'height': 0.5 } }
let g:fzf_colors = {
    \ 'border': ['fg', 'Normal'],
    \ 'info': ['fg', 'Normal'],
    \ 'prompt': ['fg', '@comment'],
    \ 'marker': ['fg', 'Normal'],
    \ 'header': ['fg', '@comment'],
    \}
command! -bang -nargs=? -complete=dir Files call fzf#vim#files(<q-args>, {'options': ['-i']}, <bang>0)
function! s:fzf_statusline()
  setlocal statusline=%#Normal#
endfunction
autocmd! User FzfStatusLine call <SID>fzf_statusline()


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
let g:ctrlsf_extra_backend_args={ 'rg': '-U' }
let g:coc_node_path = '~/.fnm/aliases/default/bin/node'
"let g:ctrlsf_regex_pattern = 1




"
" Coc
" 

" Extensions
let g:coc_global_extensions = [
    \ 'coc-dictionary',
    \ 'coc-eslint',
    \ 'coc-explorer',
    \ 'coc-json',
    \ 'coc-lua',
    \ 'coc-prettier',
    \ 'coc-prisma',
    \ 'coc-pyright',
    \ 'coc-snippets',
    \ 'coc-tsserver',
    \ 'coc-vimlsp',
    \ 'coc-word'
\ ]
"\ 'coc-styled-components',

if isdirectory('./node_modules') && isdirectory('./node_modules/prettier')
    let g:coc_global_extensions += ['coc-prettier']
endif

if isdirectory('./node_modules') && isdirectory('./node_modules/eslint')
    let g:coc_global_extensions += ['coc-eslint']
endif

" tab/shift-tab navigate through Pmenu
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction

" tab completion
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1):
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

"" accept on enter
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"



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
" units
xnoremap iu :lua require"treesitter-unit".select()<CR>
xnoremap au :lua require"treesitter-unit".select(true)<CR>
onoremap iu :<c-u>lua require"treesitter-unit".select()<CR>
onoremap au :<c-u>lua require"treesitter-unit".select(true)<CR>


"
" Keyboard Mapping
"
nmap <F1> :echo expand('%:p')<cr>
set pastetoggle=<F2>
map <F3> :set wrap!<CR>:set linebreak!<CR>
map <F6> :setlocal spell! spelllang=en_au<CR>
map <F7> :Goyo<CR>
map <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<' . synIDattr(synID(line("."),col("."),0),"name") . "> lo<" . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>

" uuid
inoremap <C-u> <C-r>=system('uuidgen \| tr "[:upper:]" "[:lower:]"')[:-2]<CR><Esc>




" Wrapped navigation
nnoremap j gj
nnoremap k gk
nnoremap gj j
nnoremap gk k

nnoremap Y y$
nnoremap <Space> .
nnoremap <MiddleMouse> :call CocAction('doHover')<CR>
nnoremap <C-p> :Files<CR>
nnoremap <C-f> :CtrlSF 
nnoremap <CR> :noh<CR><CR>

" Applying codeAction to the selected region.
" Example: `<leader>aap` for current paragraph
xmap <leader>a  <Plug>(coc-codeaction-selected)<CR>
nmap <leader>a  <Plug>(coc-codeaction-selected)<CR>

" Remap keys for applying codeAction to the current buffer.
"nmap <leader>ac  <Plug>(coc-codeaction)
" Apply AutoFix to problem on the current line.
"nmap <leader>qf  <Plug>(coc-fix-current)

" Run the Code Lens action on the current line.
nmap <leader>cl  <Plug>(coc-codelens-action)

nnoremap <Leader><Leader> :Buffers<CR>
nnoremap <Leader>b :bp<CR>
nnoremap <Leader>d1 :diffget LOCAL<CR>
nnoremap <Leader>d2 :diffget BASE<CR>
nnoremap <Leader>d3 :diffget REMOTE<CR>
nnoremap <Leader>e :CocList --normal -A diagnostics<CR>
nnoremap <Leader>f :bn<CR>
nnoremap <Leader>h :History<CR>
nnoremap <Leader>q :bp \|bw #<CR>
nnoremap <Leader>r :source $MYVIMRC<CR>
nnoremap <Leader>s :Startify<CR>
nnoremap <Leader>u :UndotreeToggle<CR>
nnoremap <Leader>v :e $MYVIMRC<CR>
nnoremap <Leader>w :TSHighlightCapturesUnderCursor<CR>

nnoremap Q @@
vnoremap Y "*y
nnoremap + <C-a>
nnoremap - <C-x>

" tig
nnoremap <Leader>tt :Tig<CR>
nnoremap <Leader>ts :TigStatus<CR>
nnoremap <Leader>th :TigOpenCurrentFile<CR>
nnoremap <Leader>tb :TigBlame<CR>
let g:tig_explorer_use_builtin_term=0

" windows
nnoremap <Leader><Tab> <C-W>w

" center on search
nnoremap n nzzzv
nnoremap N Nzzzv

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
command! Work :vsplit ~/Dropbox/work.md
command! Scratch :vsplit ~/.scratch.txt

" nops
nnoremap <Up> <nop>
nnoremap <Down> <nop>
nnoremap <Left> <nop>
nnoremap <Right> <nop>
nnoremap <BS> <nop>
nnoremap <TAB> <nop>
nnoremap q: <nop>


"
" Syntax Highlighting
"

" jsx files
augroup filetypedetect
    au BufRead,BufNewFile *.jsx set filetype=javascript
    au BufRead,BufNewFile *.tsx set filetype=typescript.tsx
    au BufNewFile,BufRead *.mdx set filetype=mdx
augroup END

" json comments
autocmd FileType json syntax match Comment +\/\/.\+$+

syntax reset
syntax on
if &diff
    syntax off
endif


"
" statusline
"
set noshowmode " dont show --insert--
set laststatus=2 " always visible
hi StatusLine ctermbg=white ctermfg=black cterm=NONE
hi StatusLineNC ctermbg=black cterm=NONE
hi NormalColor ctermbg=blue ctermfg=black
hi InsertColor ctermbg=green ctermfg=black
hi OtherColor ctermbg=yellow ctermfg=black
hi ErrorColor ctermbg=red ctermfg=black
hi VisualColor ctermbg=magenta ctermfg=black
hi InactiveColor ctermbg=grey ctermfg=black

function! StatusLine() abort
    let l:modes = {
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

    let l:modecolors = {
        \ 'normal': 'NormalColor',
        \ 'insert': 'InsertColor',
        \ 'visual': 'VisualColor',
        \ 'vblock': 'VisualColor',
        \ 'vline': 'VisualColor',
        \ 'command': 'OtherColor',
    \}

    " get the current mode - ctrl-v is hard to map
    let l:currentmode = get(l:modes, mode(), 'vblock')

    " diagnostics
    let l:info = get(b:, 'coc_diagnostic_info', {})
    let l:error = get(info, 'error', 0)
    let l:msgs = []
    if l:error | call add(l:msgs, "E". l:info['error']) | endif
    if get(l:info, 'warning', 0) | call add(l:msgs, "W". l:info['warning']) | endif
    if get(l:info, 'information', 0) | call add(l:msgs, "I". l:info['information']) | endif
    if get(l:info, 'hint', 0) | call add(l:msgs, "H". l:info['hint']) | endif
    let l:errortext = ""
    if len(msgs) | let l:errortext = "  " . join(l:msgs, ",") | endif

    " Choose color
    "if l:error && l:currentmode ==? 'normal'
        "let l:color = "%#ErrorColor#" 
    if g:actual_curwin !=? win_getid() 
        let l:color = "%#InactiveColor#" 
    else 
        let l:color = "%#" .. get(l:modecolors, l:currentmode, 'StatusLine') .. "#"
    endif

    " Construct content
    let statusline=""..l:color.." "..l:currentmode
    let statusline.="  %(%-0.75f%{&modified?\"*\":\"\"}%)"

    "let statusline.= l:errortext
    let statusline.="%="
    let statusline.="%r%w%y" "read only, preview, filetype
    let statusline.=" %v:%l/%L "
    return statusline

endfunction
set statusline=%{%StatusLine()%}

function! TabLine() abort
    let s = ''
    " loop through each tab page
    for t in range(tabpagenr('$'))
        let index = t + 1
        " select the highlighting for the buffer names
        if index == tabpagenr()
            let s .= '%#TabLineSel#'
        else
            let s .= '%#TabLine#'
        endif

        " set up tab number for mouse clicks
        let s .= '%'..index..'T'

        " set page number string
        let s .= '['..index..'] '

        let name = ''
        " loop through each buffer in a tab
        for b in tabpagebuflist(index)
            let buffer = fnamemodify(bufname(b), ':t')
            if getbufvar(b, '&buftype', '') != 'nofile' " ignore coc floating buffers
                if buffer != ''
                    let name .= buffer..'|'
                else 
                    let name .= '-|'
                endif
            endif
        endfor
        " remove last pipe
        let name = substitute(name, '.$', '', '')
        let s .= name..'  '

    endfor
    return s
endfunction
set tabline=%{%TabLine()%}
