return {
  { "David-Kunz/treesitter-unit" },
  { "adelarsq/vim-matchit" },
  { "airblade/vim-gitgutter", },
  { "arthurxavierx/vim-caser" },
  { "beloglazov/vim-online-thesaurus" },
  { "dhruvasagar/vim-zoom" },
  { "docunext/closetag.vim" },
  { "dyng/ctrlsf.vim", },
  { "echasnovski/mini.surround" },
  { "editorconfig/editorconfig-vim" },
  { "habamax/vim-godot" },
  { "iamcco/markdown-preview.nvim",             build = "cd app && yarn install", },
  { "iberianpig/tig-explorer.vim" },
  { "junegunn/fzf",                             build = function() vim.fn["fzf#install"]() end, },
  { "junegunn/fzf.vim", },
  { "junegunn/goyo.vim", },
  { "junegunn/vim-peekaboo" },
  { "jxnblk/vim-mdx-js" },
  { "liuchengxu/vista.vim", },
  { "mbbill/undotree" },
  { "mhinz/vim-startify", },
  { "neoclide/coc.nvim",                        branch = "release" },
  { "nvim-treesitter/nvim-treesitter",          build = ":TSUpdate", },
  { "nvim-treesitter/playground" },
  { "romainl/vim-qf" },
  { "scrooloose/nerdcommenter", },
  { "tpope/vim-abolish" },
  { "tpope/vim-commentary" },
  { "tpope/vim-dadbod" },
  { "tpope/vim-fugitive" },
  { "tpope/vim-markdown", },
  { "tpope/vim-repeat" },
  { "tpope/vim-rhubarb" },
  { "tpope/vim-surround" },
  { "tweekmonster/startuptime.vim" },

  -- AI
  { "nvim-lua/plenary.nvim" },
  { "stevearc/dressing.nvim" },
  { "MunifTanjim/nui.nvim" },
  { "MeanderingProgrammer/render-markdown.nvim" },

  -- Optional deps (commented)
  -- { "hrsh7th/nvim-cmp" },
  -- { "nvim-tree/nvim-web-devicons" },
  -- { "HakonHarnes/img-clip.nvim" },
  -- { "zbirenbaum/copilot.lua" },

  -- Avante
  {
    "yetone/avante.nvim",
    branch = "main",
    build = "make",
    config = function()
      require('avante').setup()
    end
  },
}
