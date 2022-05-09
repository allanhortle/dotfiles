require('nvim-treesitter.configs').setup {
    ensure_installed = "all",
    highlight = {
        enable = true,              -- false will disable the whole extension
        additional_vim_regex_highlighting = false
    }
}
local highlights = [[
[
  "as"
  "async"
  "await"
  "break"
  "case"
  "catch"
  "class"
  "const"
  "continue"
  "debugger"
  "default"
  "delete"
  "do"
  "else"
  "export"
  "extends"
  "finally"
  "for"
  "from"
  "function"
  "get"
  "if"
  "import"
  "in"
  "instanceof"
  "let"
  "new"
  "of"
  "return"
  "set"
  "static"
  "switch"
  "target"
  "throw"
  "try"
  "typeof"
  "var"
  "void"
  "while"
  "with"
  "yield"
] @keyword


[
  (true)
  (false)
  (null)
  (undefined)
  (number)
] @constant

[
  (string)
  (regex)
  (template_string)
] @string


; Settings for template strings. No idea why it works
((template_substitution
    "${" @string
    "}" @string
) @operator
 (#set! "priority" 105))

((template_substitution (identifier) @variable)
 (#set! "priority" 105))


;
; Types
[
    (type_arguments) 
    (type_annotation) 
    (type_alias_declaration)
    (type_parameters) 
] @type


(comment) @comment



]]

local jsx_highlights = [[
(jsx_expression ["{" "}"] @tag)
(jsx_attribute [(property_identifier) "="] @tag) 
(jsx_opening_element ["<" ">"] @tag)
(jsx_opening_element name: (_) @tag)
(jsx_self_closing_element name: (_) @tag)
(jsx_self_closing_element ["<" ">" "/"] @tag)
(jsx_fragment ["<" ">" "/"] @tag)
(jsx_closing_element) @tag
]];

--require('vim.treesitter.query').set_query("tsx", "highlights", highlights .. jsx_highlights)
--require('vim.treesitter.query').set_query("typescript", "highlights", highlights)


