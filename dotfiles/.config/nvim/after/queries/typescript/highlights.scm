; Keywords
[
    "import"
] @keyword


; Overrides
[
    "?"
    ":"
] @Nothing

; Types
[
    (type_arguments) 
    (type_annotation) 
    (type_alias_declaration)
    (type_parameters) 
] @type (#set! "priority" 101)

;(type_alias_declaration (identifier) @tag)
(type_alias_declaration value: (_) @type (#set! "priority" 205)) @type


; JSX
;((jsx_expression ["{" "}"] @tag) (#set! "priority" 101))
;(jsx_attribute [(property_identifier) "="] @tag) 
;(jsx_opening_element ["<" ">"] @tag)
;(jsx_opening_element name: (_) @tag)
;(jsx_self_closing_element name: (_) @tag)
;(jsx_self_closing_element ["<" ">" "/"] @tag)
;(jsx_fragment ["<" ">" "/"] @tag)
;((jsx_closing_element (identifier) @tag (#set! "priority" 205)))


; Builtin Objects
(((identifier) @keyword (property_identifier) @keyword.function)(
    (#match? @keyword "Math")
    (#match? @keyword.function "^(abs|acos|acosh|asin|asinh|atan|atanh|atan2|ceil|cbrt|expm1|clz32|cos|cosh|exp|floor|fround|hypot|imul|log|log1p|log2|log10|max|min|pow|random|round|sign|sin|sinh|sqrt|tan|tanh|trunc)$")
))

(((identifier) @keyword (property_identifier) @keyword.function)(
    (#match? @keyword "Array")
    (#match? @keyword.function "^(isArray|from|of)$")
))

(((identifier) @keyword (property_identifier) @keyword.function)(
    (#match? @keyword "Date")
    (#match? @keyword.function "^(now|parse|UTC)$")
))

(((identifier) @keyword (property_identifier) @keyword.function)(
    (#match? @keyword "JSON")
    (#match? @keyword.function "^(parse|stringify)$")
))

(((identifier) @keyword (property_identifier) @keyword.function)(
    (#match? @keyword "Promise")
    (#match? @keyword.function "^(all|allSettled|any|race|resolve|reject)$")
))

(((identifier) @keyword (property_identifier) @keyword.function)(
    (#match? @keyword "String")
    (#match? @keyword.function "^(fromCharCode|fromCodePoint|raw)$")
))

(((identifier) @keyword (property_identifier) @keyword.function)(
    (#match? @keyword "module")
    (#match? @keyword.function "^(exports)$")
))

(((identifier) @keyword (property_identifier) @keyword.function)(
    (#match? @keyword "console")
    (#match? @keyword.function "^(log|warn|error|table)$")
))
