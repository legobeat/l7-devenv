require("toggleterm").setup{
  -- size can be a number or function which is passed the current terminal
  size = 25,
  open_mapping = { [[<c-_>]] }, -- maps to both C-/ and C--
  hide_numbers = true, -- hide the number column in toggleterm buffers
  shade_filetypes = {},
  shade_terminals = true,
  start_in_insert = true,
  insert_mappings = true, -- whether or not the open mapping applies in insert mode
  terminal_mappings = true, -- whether or not the open mapping applies in the opened terminals
  persist_size = false,
  persist_mode = true,
  -- direction = 'vertical' | 'horizontal' | 'tab' | 'float',
  direction = 'horizontal',
  close_on_exit = true,
  shell = '/usr/bin/tmux -2 new', -- globally shared session; remove -As flag to not share
  -- shell = '/usr/bin/tmux new -As nvim-toggle', -- globally shared session; remove -As flag to not share
  auto_scroll = true, -- automatically scroll to the bottom on terminal output
  -- This field is only relevant if direction is set to 'float'
  float_opts = {
    -- The border key is *almost* the same as 'nvim_open_win'
    -- see :h nvim_open_win for details on borders however
    -- the 'curved' border is a custom border type
    -- not natively supported but implemented in this plugin.
    -- border = 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
    border = 'shadow',
    winblend = 0,
    -- title_pos = 'left' | 'center' | 'right', position of the title of the floating window
  },
  winbar = {
    enabled = false,
  },
}
