set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "ts-colors"


" Reset
hi Normal cterm=NONE ctermfg=white ctermbg=NONE
hi Comment ctermfg=242 cterm=italic
hi Identifier ctermfg=white cterm=NONE
hi PreProc ctermfg=white cterm=NONE
hi Type ctermfg=white cterm=NONE
hi Special ctermfg=white cterm=NONE
hi Title ctermfg=white cterm=NONE
hi Nothing ctermfg=white cterm=NONE
hi TSOperator ctermfg=white cterm=NONE

" Defaults
hi Constant ctermfg=green cterm=NONE
hi Statement ctermfg=red cterm=NONE



" Tree Sitter
hi TSBoolean ctermfg=blue cterm=NONE
hi TSConditional ctermfg=red cterm=NONE
hi TSConstBuiltin ctermfg=blue cterm=NONE
hi TSConstant ctermfg=blue cterm=NONE
hi TSKeyword ctermfg=red cterm=NONE
hi TSKeywordFunction ctermfg=red cterm=NONE
hi TSKeywordOperator ctermfg=red cterm=NONE
hi TSLabel ctermfg=yellow cterm=NONE
hi TSNumber ctermfg=blue cterm=NONE
hi TSRepeat ctermfg=red cterm=NONE
hi TSString ctermfg=green cterm=NONE
hi TSStringRegex ctermfg=green cterm=NONE
hi TSTag ctermfg=yellow cterm=NONE
hi TSTagAttribute ctermfg=yellow cterm=NONE
hi TSTagDelimiter ctermfg=yellow cterm=NONE
hi TSType ctermfg=magenta cterm=NONE
hi TSTypeBuiltin ctermfg=magenta cterm=NONE
hi TSVariableBuiltin ctermfg=red cterm=NONE
hi TSVariable ctermfg=white cterm=NONE

" Tree Sitter Overrides
hi tmuxCommands ctermfg=red cterm=NONE
hi tmuxString ctermfg=green cterm=NONE

" vim UI
hi ColorColumn ctermbg=black
hi Directory ctermfg=white
hi Error ctermbg=red ctermfg=black
hi ErrorMsg ctermfg=red ctermbg=black
hi FoldColumn ctermbg=NONE ctermfg=1
hi Folded ctermbg=NONE ctermfg=242
hi LineNr ctermfg=242
hi MatchParen ctermfg=white ctermbg=grey
hi ModeMsg ctermfg=white
hi MoreMsg ctermfg=white
hi NonText ctermfg=242
hi PMenu ctermfg=white ctermbg=234
hi PMenuSel ctermfg=black ctermbg=green
hi Question ctermfg=white
hi Search ctermbg=grey
hi SignColumn ctermbg=NONE
hi SpecialKey ctermfg=white
hi SpellBad ctermfg=red ctermbg=NONE cterm=underline
hi SpellCap ctermfg=yellow ctermbg=NONE cterm=underline
hi SpellLocal ctermfg=NONE ctermbg=NONE cterm=NONE
hi TabLine ctermfg=NONE ctermbg=NONE cterm=NONE
hi TabLineFill ctermfg=NONE ctermbg=NONE cterm=NONE
hi TabLineSel ctermfg=green ctermbg=NONE cterm=NONE
hi VertSplit ctermfg=white cterm=NONE ctermbg=NONE
hi Visual ctermbg=240
hi WarningMsg ctermfg=yellow ctermbg=black
hi StartifyHeader ctermfg=yellow 
hi StartifySection ctermfg=242 
hi StartifyNumber ctermfg=blue 
hi StartifyBracket ctermfg=blue 

" vim script
hi vimCommand ctermfg=red
hi vimString ctermfg=green
hi vimHiCtermColor ctermfg=blue
hi vimFgBgAttrib ctermfg=blue
hi vimHiAttrib ctermfg=blue
hi vimNotation ctermfg=yellow
hi vimBracket ctermfg=yellow
hi vimMapModKey ctermfg=yellow

" git diff
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
hi DiffAdd ctermfg=green ctermbg=NONE cterm=NONE
hi DiffDelete ctermfg=red ctermbg=NONE cterm=NONE
hi DiffChange ctermfg=white ctermbg=NONE cterm=NONE
hi DiffText ctermfg=blue ctermbg=NONE cterm=NONE


"
" markdown
hi markdownBold cterm=bold
hi markdownCode ctermfg=magenta
hi markdownCodeDelimiter ctermfg=magenta
hi markdownH1 ctermfg=yellow
hi markdownH1Delimiter ctermfg=yellow
hi markdownH2 ctermfg=green
hi markdownH2Delimiter ctermfg=green
hi markdownH3 ctermfg=blue
hi markdownH3Delimiter ctermfg=blue
hi markdownH4 ctermfg=magenta
hi markdownH4Delimiter ctermfg=magenta
hi markdownH5 ctermfg=red
hi markdownH5Delimiter ctermfg=red
hi TSTitle ctermfg=yellow
hi TSTitleH2 ctermfg=green
hi TSTitleH3 ctermfg=blue
"hi markdownHeadingRule ctermfg=yellow
"hi markdownItalic cterm=italic
