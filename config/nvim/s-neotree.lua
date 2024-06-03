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
    name = {
      trailing_slash = false,
      use_git_status_colors = true,
      highlight = "NeoTreeFileName",
    },
  }
)
