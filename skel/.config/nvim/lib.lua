-- Deletes all trailing whitespaces in a file
  -- https://github.com/lucasvianav/nvim/blob/62ac5c2aa8abb25094d7d896c3b58a0936c13984/lua/functions/utilities.lua#L39-L48
  -- https://vi.stackexchange.com/questions/37421/how-to-remove-neovim-trailing-white-space
function _G.trim_trailing_whitespaces()
  local current_view = vim.fn.winsaveview()
  vim.cmd([[keeppatterns %s/\s\+$//e]])
  vim.fn.winrestview(current_view)
end

-- Auto-trim whitespace on save, except for binaries and diffs
vim.api.nvim_create_autocmd({ 'BufWritePre' }, {
  pattern = {'*'},
  callback = function(ev)
    if not vim.o.binary and vim.o.filetype ~= 'diff' then
      _G.trim_trailing_whitespaces()
    end
  end,
})
