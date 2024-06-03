-------------
-- TreeSitter
-------------
require('nvim-treesitter.configs').setup {
  -- A list of parser names, or "all"
  ensure_installed = { 'c', 'nix', 'rust', 'go','python', 'typescript', 'javascript', 'html', 'hcl', 'make', 'yaml', 'toml', 'ruby', 'bash', 'dockerfile' },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- List of parsers to ignore installing (for 'all')
  -- ignore_install = { 'lua' },
  -- disable = { 'lua' },
  highlight = {
    enable = true,
  },
  -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
  -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
  -- Using this option may slow down your editor, and you may see some duplicate highlights.
  -- Instead of true it can also be a list of languages
  additional_vim_regex_highlighting = false,
}

