if exists('b:current_syntax')
  finish
endif

" Later definitions win at the same position, so each block overrides the one above.
" A bare line is logic and stays unstyled; it's the prose the rest hangs off.
syn match sketchRef   "^\s*->.*$" contains=sketchArrow
syn match sketchArrow "->" contained
syn match sketchBlock "^\s*[^#?![:space:]].*:\s*$" contains=sketchColon
syn match sketchColon ":\s*$" contained
syn match sketchArea  "^\[[^]]\+\]\s*$"

syn match sketchAsk "^\s*?.*$"
syn match sketchDo  "^\s*!.*$"

syn match sketchAgent "^\s*#.*$"

" A `#` followed by two or more spaces continues the block above it.
syn match sketchOk         "^\s*#\s*ok\>.*$"
syn match sketchAgentFind  "^\s*#\s*!.*\%(\n\s*#\s\{2,\}.*\)*"
syn match sketchAgentAsk   "^\s*#\s*?.*\%(\n\s*#\s\{2,\}.*\)*"

syn match sketchPause  "^pause\s*$"
syn match sketchHeader "^#!.*$"

syn sync fromstart

hi def link sketchArea       @tag
hi def link sketchBlock      @tag
hi def link sketchColon      @tag
hi def link sketchRef        @constant
hi def link sketchArrow      @constant
hi def link sketchAsk        Question
hi def link sketchDo         Statement
hi def link sketchPause      WarningMsg
hi def link sketchAgent      Comment
hi def link sketchOk         Comment
hi def link sketchAgentFind  @keyword
hi def link sketchAgentAsk   WarningMsg
hi def link sketchHeader     Comment

let b:current_syntax = 'sketch'
