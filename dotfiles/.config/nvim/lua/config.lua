require('nvim-treesitter.configs').setup {
    ensure_installed = "all",
    highlight = {
        enable = true,              -- false will disable the whole extension
        additional_vim_regex_highlighting = false
    }
}

require"nvim-treesitter.highlight".set_custom_captures {
    -- Highlight the @foo.bar capture group with the "Identifier" highlight group.
    ["text.titleH2"] = "TSTitleH2",
    ["text.titleH3"] = "TSTitleH3"
}

