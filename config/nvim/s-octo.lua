require('octo').setup({
  use_local_fs = true,
  default_remote = {'mm', 'origin', 'upstream'},
  default_merge_method = 'rebase', -- commit, merge, rebase
  -- ssh_aliases = {
  --   ["github.com-user"] = "github.com"
  -- },
  picker_config = {
    use_emojis = false, -- only used by "fzf-lua" picker for now
    -- mappings = {                           -- mappings for the pickers
     --  open_in_browser = { lhs = "<C-m>", desc = "open issue in browser" },
    --   copy_url = { lhs = "<C-y>", desc = "copy url to system clipboard" },
     --  checkout_pr = { lhs = "<C-o>", desc = "checkout pull request" },
    --   merge_pr = { lhs = "<C-r>", desc = "merge pull request" },
    -- },
  },
})
local octo_prs = function()
  vim.cmd('Octo pr list')
end
-- set up manually to not spray tokens everywhere
-- vim.api.nvim_create_user_command('Oct', octo, {})
vim.api.nvim_create_user_command('PRs', octo_prs, {})
vim.api.nvim_create_user_command('Prs', octo_prs, {})
