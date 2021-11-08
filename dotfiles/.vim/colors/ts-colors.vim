set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "puffin"

"
" Basic
"
hi Normal cterm=none ctermfg=white ctermbg=none
hi Comment ctermfg=242 cterm=italic
hi Constant ctermfg=white cterm=none
hi Statement ctermfg=white cterm=none
hi Identifier ctermfg=white cterm=none
hi PreProc ctermfg=white cterm=none
hi Type ctermfg=white cterm=none
hi Special ctermfg=white cterm=none
hi Statement ctermfg=white cterm=none
hi Title ctermfg=white cterm=none
hi Nothing ctermfg=white cterm=none


" Tree Sitter
hi TSConditional ctermfg=red cterm=none
hi TSConstBuiltin ctermfg=blue cterm=none
hi TSBoolean ctermfg=blue cterm=none
hi TSNumber ctermfg=blue cterm=none
hi TSKeyword ctermfg=red cterm=none
hi TSVariableBuiltin ctermfg=red cterm=none
hi TSKeywordFunction ctermfg=red cterm=none
hi TSKeywordOperator ctermfg=red cterm=none
hi TSLabel ctermfg=yellow cterm=none
hi TSString ctermfg=green cterm=none
hi TSTag ctermfg=yellow cterm=none
hi TSTagDelimiter ctermfg=yellow cterm=none
hi TSTagAttribute ctermfg=yellow cterm=none
hi TSType ctermfg=magenta cterm=none

" Tree Sitter Overrides
hi cssTSProperty ctermfg=red cterm=none
hi cssTSType ctermfg=yellow cterm=none
hi cssTSString ctermfg=blue cterm=none
hi graphqlTSVariable ctermfg=yellow cterm=none

" tmux
hi tmuxCommands ctermfg=red cterm=none
hi tmuxString ctermfg=green cterm=none


"
" vim UI
"
hi ColorColumn ctermbg=black
hi Directory ctermfg=white
hi Error ctermbg=red ctermfg=black
hi ErrorMsg ctermfg=red ctermbg=black
hi FoldColumn ctermbg=none ctermfg=1
hi Folded ctermbg=none ctermfg=242
hi LineNr ctermfg=242
hi MatchParen ctermfg=white ctermbg=grey
hi ModeMsg ctermfg=white
hi MoreMsg ctermfg=white
hi NonText ctermfg=242
hi PMenu ctermfg=white ctermbg=234
hi PMenuSel ctermfg=black ctermbg=green
hi Question ctermfg=white
hi Search ctermbg=grey
hi SignColumn ctermbg=none
hi SpecialKey ctermfg=white
hi SpellBad ctermfg=red ctermbg=none cterm=underline
hi SpellCap ctermfg=yellow ctermbg=none cterm=underline
hi SpellLocal ctermfg=none ctermbg=none cterm=none
hi TabLine ctermfg=none ctermbg=none cterm=none
hi TabLineFill ctermfg=none ctermbg=none cterm=none
hi TabLineSel ctermfg=green ctermbg=none cterm=none
hi VertSplit ctermfg=white cterm=none ctermbg=none
hi Visual ctermbg=240
hi WarningMsg ctermfg=yellow ctermbg=black
hi StartifyHeader ctermfg=yellow 
hi StartifySection ctermfg=242 

"
" vim
"
hi vimCommand ctermfg=red
hi vimString ctermfg=green
hi vimHiCtermColor ctermfg=blue
hi vimFgBgAttrib ctermfg=blue
hi vimHiAttrib ctermfg=blue
hi vimNotation ctermfg=yellow
hi vimBracket ctermfg=yellow
hi vimMapModKey ctermfg=yellow


"
" diff
"

" git
hi diffAdded ctermfg=green ctermbg=NONE
hi diffRemoved ctermfg=red ctermbg=NONE
hi diffChanged ctermfg=blue ctermbg=NONE
hi diffText ctermfg=white ctermbg=NONE
hi diffFile ctermfg=yellow
hi diffIndexLine ctermfg=yellow
hi diffNewFile ctermfg=yellow
hi diffLine ctermfg=magenta
hi diffSubname ctermfg=magenta

" vimdiff
hi DiffAdd ctermfg=green ctermbg=none cterm=none
hi DiffDelete ctermfg=red ctermbg=none cterm=none
hi DiffChange ctermfg=white ctermbg=none cterm=none
hi DiffText ctermfg=blue ctermbg=none cterm=none


