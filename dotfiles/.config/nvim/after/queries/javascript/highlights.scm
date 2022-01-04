; keywords

[
    "import"
    "from"
] @keyword

; JSX
((jsx_expression ["{" "}"] @tag) (#set! "priority" 101))
(jsx_attribute [(property_identifier) "="] @tag) 
(jsx_opening_element ["<" ">"] @tag)
(jsx_opening_element name: (_) @tag)
(jsx_self_closing_element name: (_) @tag)
(jsx_self_closing_element ["<" ">" "/"] @tag)
(jsx_fragment ["<" ">" "/"] @tag)
((jsx_closing_element (identifier) @tag (#set! "priority" 205)))


; Overrides
[
    "?"
    ":"
] @Nothing


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


