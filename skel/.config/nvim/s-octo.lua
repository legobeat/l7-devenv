require('octo').setup({
  use_local_fs = true,
  default_remote = {'mm', 'origin', 'upstream'},
  default_merge_method = 'rebase', -- commit, merge, rebase
  ssh_aliases = {
    ["github.com-.*"] = "github.com"
  },
  gh_env = function()
    -- TODO: GH token from file instead of env
    return { GITHUB_TOKEN = os.getenv("GITHUB_TOKEN") }
  end,
  default_to_projects_v2 = true,
  picker_config = {
    use_emojis = true, -- only used by "fzf-lua" picker for now
  },
  pull_requests = {
    always_select_remote_on_create = true
  },
  snippet_context_lines = 4,
  timeout = 20000,
})
local octo_prs = function()
  vim.cmd('Octo pr list')
end
-- set up manually to not spray tokens everywhere
-- vim.api.nvim_create_user_command('Oct', octo, {})
vim.api.nvim_create_user_command('PRs', octo_prs, {})
vim.api.nvim_create_user_command('Prs', octo_prs, {})
