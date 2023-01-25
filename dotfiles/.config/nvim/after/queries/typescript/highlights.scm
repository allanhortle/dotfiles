;; extends

[
    "as"
] @keyword

[
    ((type_annotation (":") @none))
] @none

[
    (undefined)
] @constant


[
    ("type" (#set! "priority" 1000))
    (type_arguments) 
    (type_annotation) 
    (type_alias_declaration (#set! "priority" 1000))
    (type_parameters) 
    ((export_statement (type_alias_declaration)))
] @type







