-- Filetype -> parser mapping for cases where the names diverge.
vim.treesitter.language.register('tsx', { 'typescript.tsx', 'typescriptreact' })
vim.treesitter.language.register('bash', 'sh')
vim.treesitter.language.register('git_config', 'gitconfig')
vim.treesitter.language.register('git_rebase', 'gitrebase')
vim.treesitter.language.register('diff', 'gitdiff')

vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
    if lang and pcall(vim.treesitter.language.add, lang) then
      pcall(vim.treesitter.start, args.buf, lang)
    end
  end,
})

require('mini.surround').setup()
require('tsc').setup()
