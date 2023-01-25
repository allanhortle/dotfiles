require('nvim-treesitter.configs').setup {
    ensure_installed = "all",
    ignore_install = { "php", "phpdoc" },
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = true
    }
}

