-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  _G.enable_lsp_keybindings(client, bufnr)
end

local lsp_flags = {
  debounce_text_changes = 150,
}
-- https://github.com/starcraftman/dot/blob/master/files/vimrc#L15-L16
require('lspconfig')['pyright'].setup{
    on_attach = on_attach,
    flags = lsp_flags,
    cmd = { "pyright-langserver", "--stdio", "-p", "~/.config/nvim/pyright.toml" },
    settings = {
      pyright = {
        reportPrivateImportUsage = false,
        report_private_import_usage = false,
      },
      python = {
        reportPrivateImportUsage = false,
        report_private_import_usage = false,
        analysis = {
          autoSearchPaths = true,
          diagnosticMode = "workspace",
          useLibraryCodeForTypes = true,
          reportPrivateImportUsage = false,
          report_private_import_usage = false,
        }
      }
    }
}
-- nix
require('lspconfig')['rnix'].setup{
    on_attach = on_attach,
    flags = lsp_flags,
}
-- go
require('lspconfig')['gopls'].setup{
    on_attach = on_attach,
    flags = lsp_flags,
    settings = {
      gopls = {
        analyses = {
          unusedparams = true,
        },
        staticcheck = true,
      },
      ["logVerbosity"] = 'verbose'
    }
}
-- typescript
-- require('lspconfig')['denols'].setup{
require('lspconfig')['tsserver'].setup{
    on_attach = on_attach,
    flags = lsp_flags,
    settings = {
      ["logVerbosity"] = 'verbose'
    }
}
-- terraform
require('lspconfig')['tflint'].setup{
    on_attach = on_attach,
    flags = lsp_flags,
}
-- c/c++
require('lspconfig')['ccls'].setup{
   on_attach = on_attach,
   flags = lsp_flags,
}
-- rust
require('lspconfig')['rust_analyzer'].setup{
    on_attach = on_attach,
    flags = lsp_flags,
    -- Server-specific settings...
    settings = {
      ["rust-analyzer"] = {}
    }
}
