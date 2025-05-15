-- lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Set leader key before lazy.nvim setup
vim.g.mapleader = " "
vim.g.maplocalleader = " "



-- Load plugins from lua/plugins/init.lua file
require("lazy").setup(require("plugins"))

-- Set up plugin configurations
-- require('plugins.config').setup_all()

-- Set up mini.surround
require('mini.surround').setup()

-- Set up Treesitter configuration
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

-- Source existing Vim config for compatibility
vim.cmd([[
set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath=&runtimepath
source ~/.vimrc
]])
