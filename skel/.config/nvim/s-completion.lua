require('mini.completion').setup({
  -- defaults commented out
  -- delay = { completion = 100, info = 100, signature = 50 },

  -- window = {
  --   info = { height = 25, width = 80, border = 'none' },
  --   signature = { height = 25, width = 80, border = 'none' },
  -- },

  -- lsp_completion = {
    -- source_func = 'completefunc',
    --auto_setup = true,
    -- process_items = --<function: filters out snippets; sorts by LSP specs>,
  -- },

  -- Fallback action. It will always be run in Insert mode. To use Neovim's
  -- built-in completion (see `:h ins-completion`), supply its mapping as
  -- string. Example: to use 'whole lines' completion, supply '<C-x><C-l>'.
  -- fallback_action = --<function: like `<C-n>` completion>,
  fallback_action = '<C-x><C-l>'

  -- Module mappings. Use `''` (empty string) to disable one. Some of them
  -- might conflict with system mappings.
  -- mappings = {
  --   force_twostep = '<C-Space>', -- Force two-step completion
  --   force_fallback = '<A-Space>', -- Force fallback completion
  -- },

  -- Whether to set Vim's settings for better experience (modifies
  -- `shortmess` and `completeopt`)
  --set_vim_settings = true,
})
