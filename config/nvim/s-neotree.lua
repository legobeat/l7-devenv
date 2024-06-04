require('neo-tree').setup({
    git_status = {
      symbols = {
        -- Change type
        added     = "",
        deleted   = "",
        modified  = "",
        renamed   = "",
        -- Status type
        --untracked = "",
        untracked = "",
        ignored   = "",
        unstaged  = "",
        staged    = "",
        conflict   = "✖",
        --conflict  = "",
      },
      align = "right",
    },
    icon = {
      folder_closed = "",
      folder_open = "",
      folder_empty = "ﰊ",
      default = "-",
      -- highlight = "NeoTreeFileIcon"
      highlight = ""
    },
    bind_to_cwd = false, -- true creates a 2-way binding between vim's cwd and neo-tree's root
    name = {
      trailing_slash = false,
      use_git_status_colors = true,
      highlight = "NeoTreeFileName",
    },
  }
)
