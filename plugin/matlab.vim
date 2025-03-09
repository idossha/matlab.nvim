" MATLAB.nvim - A Neovim plugin for MATLAB development
" Maintainer: Your Name
" License: MIT

" Prevent loading this plugin multiple times
if exists('g:loaded_matlab_nvim')
  finish
endif
let g:loaded_matlab_nvim = 1

" Save user options
let s:save_cpo = &cpo
set cpo&vim

" Define commands
command! -nargs=0 MatlabExecuteCell lua require('matlab.commands').execute_cell()
command! -nargs=0 MatlabExecuteFile lua require('matlab.commands').execute_file()
command! -range MatlabExecuteSelection lua require('matlab.commands').execute_selection()
command! -nargs=0 MatlabToggleWorkspace lua require('matlab.workspace').toggle()
command! -nargs=0 MatlabNextCell lua require('matlab.cells').goto_next_cell()
command! -nargs=0 MatlabPrevCell lua require('matlab.cells').goto_prev_cell()

" Set up highlight groups for cell markers
augroup matlab_highlight
  autocmd!
  autocmd ColorScheme * highlight default MatlabCellSeparator guifg=#6c7086 ctermfg=242
  autocmd ColorScheme * highlight default MatlabCellTitle gui=bold guifg=#7aa2f7 cterm=bold ctermfg=39
augroup END

" Initialize highlight groups
highlight default MatlabCellSeparator guifg=#6c7086 ctermfg=242
highlight default MatlabCellTitle gui=bold guifg=#7aa2f7 cterm=bold ctermfg=39

" Define filetype detection
augroup matlab_filetype
  autocmd!
  autocmd BufNewFile,BufRead *.m set filetype=matlab
augroup END

" Restore user options
let &cpo = s:save_cpo
unlet s:save_cpo
