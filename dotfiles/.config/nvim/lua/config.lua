require('nvim-treesitter.configs').setup {
  ensure_installed = {
    "bash",
    "css",
    "csv",
    "diff",
    "dockerfile",
    "gdscript",
    "git_config",
    "git_rebase",
    "gitattributes",
    "graphql",
    "html",
    "javascript",
    "json",
    "jsonc",
    "lua",
    "prisma",
    "python",
    "sql",
    "tsx",
    "typescript",
    "vim",
    "yaml"
  },
  highlight = {
    enable = true,
    additional_vim_regex_highlighting = true
  }
}

require('mini.surround').setup()
require('tsc').setup()
