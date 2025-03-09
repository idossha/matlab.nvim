if exists('g:loaded_matlab_nvim')
  finish
endif
let g:loaded_matlab_nvim = 1

" Load Lua functionality
lua require('matlab').setup({})