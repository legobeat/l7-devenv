let g:python3_host_prog = '/usr/bin/python3'

" user preferences. some of these are subjective
set nocompatible
set encoding=utf-8
" set mouse=
set tabstop=2 softtabstop=2 shiftwidth=2 expandtab smarttab autoindent
set incsearch smartcase nogdefault showmatch
set autochdir
set wrap
set termguicolors
set list           " show silent characters
set hidden         " Hide buffers when they are abandoned
set backupcopy=yes " Default: `auto`. yes makes sure webpack watch et al recognize writes properly

let g:netrw_banner=0
let g:netrw_liststyle=3

" autocreate swap backup dir
let g:backupdir=expand('~/.local/share/nvim/swap')
if !isdirectory(g:backupdir)
  call mkdir(g:backupdir, "p")
endif
let &backupdir=g:backupdir

if has("autocmd")
  filetype on
  filetype plugin indent on
  autocmd FileType go,make,python setlocal ts=4 sts=4 sw=4 noexpandtab
  autocmd FileType yaml,yml       setlocal ts=2 sts=2 sw=2 expandtab indentkeys-=0# indentkeys-=<:>
endif
if has("syntax")
  syntax on
endif

packloadall

runtime lib.lua
runtime keys.lua

" silently ignore missing plugins
try
  runtime s-bufferlinetabs.lua
catch
endtry
try
  runtime s-lualine.lua
catch
endtry
try
  runtime s-neotree.lua
catch
endtry
try
  runtime s-lsp.lua
catch
endtry
try
  runtime s-toggleterm.lua
catch
endtry
try
  runtime s-completion.lua
catch
endtry
try
  runtime theme.lua
catch
endtry
try
  colorscheme tokyonight-moon
catch
endtry
try
  runtime s-octo.lua
catch
endtry
