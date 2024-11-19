set background=dark
hi clear
if exists("syntax_on")
  syntax reset
endif
let g:colors_name = "ts-colors"

" basics
"hi def link @type.builtin @type
hi @none ctermfg=white cterm=NONE
hi @keyword ctermfg=red cterm=NONE
hi @constant ctermfg=blue cterm=NONE
hi @string ctermfg=green cterm=NONE
hi @type ctermfg=yellow cterm=NONE
"hi @type ctermfg=yellow cterm=NONE
hi @tag ctermfg=yellow cterm=NONE
hi @comment ctermfg=242 cterm=italic
"hi typescriptIdentifierName ctermfg=red ctermbg=blue cterm=none

" Reset ? Default vim
hi! def link Comment @comment
hi Normal cterm=NONE ctermfg=white ctermbg=NONE
hi Identifier ctermfg=white cterm=NONE
hi PreProc ctermfg=white cterm=NONE
"hi Type ctermfg=white cterm=NONE
hi Special ctermfg=white cterm=NONE
hi Title ctermfg=white cterm=NONE
hi Constant ctermfg=white cterm=NONE
hi Statement ctermfg=white cterm=NONE
hi Function ctermfg=white cterm=NONE


" Tree Sitter
hi def link @preproc @comment
hi def link @markup.raw @comment

" Nothings
hi def link @conditional @none
hi def link @operator @none
hi def link @variable @none
hi def link @variable.member @none
hi def link @function @none
hi def link @variable.tsx @none
hi def link @function.method.call @none
hi def link @punctuation.bracket @none


hi def link @include @keyword
hi def link @keyword.function @keyword
hi def link @keyword.operator @keyword
hi def link @exception @keyword
hi def link @repeat @keyword
hi def link @variable.builtin @keyword
hi def link @keyword.type.typescript @keyword

hi def link @boolean @constant
hi def link @constant.builtin @constant
hi def link @number @constant

hi def link @string @string
hi def link @string.regexp @string

hi def link @tag.attribute @tag
hi def link @label @tag
hi def link @property @tag
hi def link @tag.builtin.tsx @tag

" Markdown
hi def link @label.markdown @comment
hi def link @markup.heading @tag
hi def link @markup.heading.2 @string
hi def link @markup.heading.3 @constant
hi def link @markup.link @constant






" Tree Sitter Overrides
hi tmuxCommands ctermfg=red cterm=NONE
hi tmuxString ctermfg=green cterm=NONE

" vim UI
hi ColorColumn ctermfg=white ctermbg=black cterm=NONE
hi Directory ctermfg=white
hi Error ctermbg=red ctermfg=black
hi ErrorMsg ctermfg=red ctermbg=black
hi FoldColumn ctermbg=NONE ctermfg=1
hi Folded ctermbg=NONE ctermfg=242
hi LineNr ctermfg=242
hi MatchParen ctermbg=NONE ctermfg=NONE cterm=underline
hi CocUnderline cterm=undercurl
hi CocErrorHighlight cterm=undercurl
hi CocWarningHighlight cterm=undercurl
hi CocHintHighlight cterm=none
hi CocDeprecatedHighlight cterm=strikethrough
hi ModeMsg ctermfg=white
hi MoreMsg ctermfg=white
hi NonText ctermfg=242

hi Pmenu ctermfg=white ctermbg=black cterm=NONE
hi PmenuSel ctermfg=white ctermbg=238 cterm=NONE
hi PmenuKindSel ctermfg=white ctermbg=238 term=NONE

hi NormalFloat ctermfg=white ctermbg=234
hi Question ctermfg=white
hi Search ctermbg=grey
hi SignColumn ctermbg=NONE
hi SpecialKey ctermfg=white
hi SpellBad ctermfg=red ctermbg=NONE cterm=undercurl
hi SpellCap ctermfg=yellow ctermbg=NONE cterm=underline
hi SpellLocal ctermfg=NONE ctermbg=NONE cterm=NONE
hi TabLine ctermfg=NONE ctermbg=NONE cterm=NONE
hi TabLineFill ctermfg=NONE ctermbg=NONE cterm=NONE
hi TabLineSel ctermfg=green ctermbg=NONE cterm=NONE
hi VertSplit ctermfg=white cterm=NONE ctermbg=none
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
hi markdownCode ctermfg=red
hi markdownCodeDelimiter ctermfg=242
hi markdownCodeBlock ctermfg=242
hi markdownH1 ctermfg=yellow
hi @text.title ctermfg=yellow
hi markdownH1Delimiter ctermfg=yellow
hi markdownH2 ctermfg=green
hi @text.titleH2 ctermfg=green
hi markdownH2Delimiter ctermfg=green
hi markdownH3 ctermfg=blue
hi markdownH3Delimiter ctermfg=blue
hi markdownH4 ctermfg=magenta
hi markdownH4Delimiter ctermfg=magenta
hi markdownH5 ctermfg=red
hi markdownH5Delimiter ctermfg=red

"
" Chordpro
hi chordproTag ctermfg=242
hi chordproDirective ctermfg=242
hi chordproDirWithOpt ctermfg=242
hi chordproOptions ctermfg=242
hi chordproChord ctermfg=blue
hi chordproBracket ctermfg=blue

