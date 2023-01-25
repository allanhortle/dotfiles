;; extends
; keywords

[
    "import"
    "from"
    "catch"
    "default"
    "finally"
    "for"
    "from"
    "import"
    "of"
    "throw"
    "try"
    "while"
] @keyword


[
    (undefined)
] @constant

; Overrides
[
    "?"
    ":"
] @none

(ternary_expression ["?" ":"] @conditional (#set! "priority" 205))

;(regex "/" @string.regex (#set! "priority" 1000)); Regex delimiters

(template_substitution ["${" "}"] @comment)


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


