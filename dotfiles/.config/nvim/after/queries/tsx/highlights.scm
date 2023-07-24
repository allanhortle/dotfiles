;; extends
; inherits: typescript,jsx
((jsx_expression ["{" "}"] @tag) (#set! "priority" 101))
(jsx_attribute [(property_identifier) "="] @tag) 
(jsx_opening_element ["<" ">"] @tag)
(jsx_opening_element name: (_) @tag)
(jsx_self_closing_element name: (_) @tag)
(jsx_self_closing_element ["<" ">" "/"] @tag)
((jsx_closing_element (identifier) @tag (#set! "priority" 207)))





