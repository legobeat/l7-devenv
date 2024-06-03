require('bufferline').setup{
  highlights = {
    fill = {
      ctermbg = 7,
      ctermfg = 0,
    }
  },
  options = {
    diagnostics = 'nvim_lsp',
    always_show_bufferline = true,
    show_buffer_icons = false,
    show_buffer_close_icons = false,
    show_close_icon = false,
    sort_by = 'insert_after_current',
    -- separator_style = 'slant' | 'thick' | 'thin' | { 'any', 'any' }
    separator_style = 'thin',
  }
}

