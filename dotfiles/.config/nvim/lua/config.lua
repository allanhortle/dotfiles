require('nvim-treesitter.configs').setup {
    ensure_installed = "all",
    ignore_install = { "php", "phpdoc" },
    highlight = {
        enable = true,              -- false will disable the whole extension
        additional_vim_regex_highlighting = false
    }
}

local actions = require('telescope.actions');
require('telescope').setup({
    defaults = {
        prompt_prefix = " ",
        mappings = {
            i = {
                ["<esc>"] = actions.close,
            },
        }
    },
    pickers = {
        buffers = {
            theme = 'dropdown',
            previewer = false,
        },
        find_files = {
            find_command = {"rg","--ignore","--hidden","--files", "--glob", "!.git"},
            theme = 'dropdown',
            previewer = false,
        }
    }
})

