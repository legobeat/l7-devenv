vim.keymap.set('', '<C-h>', '<C-w>h', {desc = 'Navigate window left' })
vim.keymap.set('', '<C-j>', '<C-w>j', {desc = 'Navigate window down' })
vim.keymap.set('', '<C-k>', '<C-w>k', {desc = 'Navigate window up' })
vim.keymap.set('', '<C-l>', '<C-w>l', {desc = 'Navigate window right' })
-- same in terminal
vim.keymap.set('t', '<C-h>', '<C-\\><C-N><C-w>h', {desc = 'Navigate terminal window left' })
vim.keymap.set('t', '<C-j>', '<C-\\><C-N><C-w>j', {desc = 'Navigate terminal window down' })
vim.keymap.set('t', '<C-k>', '<C-\\><C-N><C-w>k', {desc = 'Navigate terminal window up' })
vim.keymap.set('t', '<C-l>', '<C-\\><C-N><C-w>l', {desc = 'Navigate terminal window right' })

vim.keymap.set('n', 'J', ':bp<CR>', {desc = 'Previous buffer' , silent = true})
vim.keymap.set('n', 'K', ':bn<CR>', {desc = 'Next buffer' , silent = true})
vim.keymap.set('n', '<C-c>', ':bn<CR>:bd#<CR>', {desc = 'Close buffer without closing window', silent = true})

-- tab nav (though i prefer buffers usually)
vim.keymap.set('n', 'H', 'gT', {desc = 'Previous tab'})
vim.keymap.set('n', 'L', 'gt', {desc = 'Next tab'})

-- plugins
vim.keymap.set('n', '<C-n>',     ':Neotree filesystem toggle reveal left<CR>', {desc = 'Toggle left file tree', silent = true})
vim.keymap.set('n', '<leader>n', ':Neotree filesystem toggle reveal left<CR>', {desc = 'Toggle left file tree', silent = true})
vim.keymap.set('n', '<C-g>',     ':Neotree source=git_status toggle position=right<CR>', {desc = 'Toggle right git status', silent = true })
vim.keymap.set('n', '<leader>g', ':Neotree source=git_status toggle position=right<CR>', {desc = 'Toggle right git status', silent = true })

vim.keymap.set('n', '<F4>', ':set invnumber<CR>', {desc='Toggle line numbers', silent = true})
vim.keymap.set('', '<F5>', _G.trim_trailing_whitespaces, {desc = 'Trim trailing whitespace', silent = true })

-- See `:help vim.diagnostic.*` for documentation on below functions
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, {desc = 'Inpect diagnostic', silent = true})
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, {desc = 'Previous diagnostic', silent = true})
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, {desc = 'Next diagnostic', silent = true})
vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist, {desc = 'Show diagnostics location list', silent = true})


-- These are enabled conditionally when LSP activated inside s-lsp.lua
function _G.enable_lsp_keybindings(client, bufnr)
  -- Enable completion triggered by <c-x><c-o>
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  -- See `:help vim.lsp.*` for documentation on any below functions
  vim.keymap.set('n', 'gD', function() vim.lsp.buf.declaration() end, { desc = 'Go to declaration', silent = true, buffer = bufnr })
  vim.keymap.set('n', 'gd', function() vim.lsp.buf.definition() end, { desc = 'Go to definition', silent = true, buffer = bufnr })
  vim.keymap.set('n', '"', function() vim.lsp.buf.hover() end, {desc = 'Show hover', silent = true, buffer = bufnr })
  vim.keymap.set('n', 'gi', function() vim.lsp.buf.implementation() end, {desc = 'Go to implementation', silent = true, buffer = bufnr })
  vim.keymap.set('n', '<C-k>', function() vim.lsp.buf.signature_help() end, {desc = 'Show signature help', silent = true, buffer = bufnr })
  vim.keymap.set('n', '<space>wa', function() vim.lsp.buf.add_workspace_folder() end, {desc = 'Add workspace folder', silent = true, buffer = bufnr })
  vim.keymap.set('n', '<space>wr', function() vim.lsp.buf.remove_workspace_folder() end, {desc = 'Remove workspace folder', silent = true, buffer = bufnr })
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, {desc = 'List workspace folders', silent = true, buffer = bufnr })
  vim.keymap.set('n', '<space>D', function() vim.lsp.buf.type_definition() end, {desc = 'Go to type definition', silent = true, buffer = bufnr })
  vim.keymap.set('n', '<space>rn', function() vim.lsp.buf.rename() end, {desc = 'Rename', silent = true, buffer = bufnr })
  vim.keymap.set('n', '<space>ca', function() vim.lsp.buf.code_action() end, {desc = 'Select code action', silent = true, buffer = bufnr })
  vim.keymap.set('n', 'gr', function() vim.lsp.buf.references() end, {desc = 'Show references', silent = true, buffer = bufnr })
  vim.keymap.set('n', '<space>f', function() vim.lsp.buf.format() end, {desc = 'Format buffer', silent = true, buffer = bufnr })
end

-- convenient navigation out of ToggleTerm
function _G.set_terminal_keymaps()
  local opts = {buffer = 0}
  vim.keymap.set('t', '<esc>', [[<C-\><C-n>]], opts)
  --vim.keymap.set('t', 'jk', [[<C-\><C-n>]], opts)
  --vim.keymap.set('t', '<C-h>', [[<Cmd>wincmd h<CR>]], opts)
  vim.keymap.set('t', '<C-j>', [[<Cmd>wincmd j<CR>]], opts)
  vim.keymap.set('t', '<C-k>', [[<Cmd>wincmd k<CR>]], opts)
  -- vim.keymap.set('t', '<C-l>', [[<Cmd>wincmd l<CR>]], opts)
  vim.keymap.set('t', '<C-w>', [[<C-\><C-n><C-w>]], opts)
end

-- if you want these for all terminals in nvim, use term://* instead
vim.cmd('autocmd! TermOpen term://*toggleterm#* lua set_terminal_keymaps()')

-- vim.keymap.set('n', 'lhs', 'rhs')
-- same as vimscript
-- nnoremap lhs rhs
