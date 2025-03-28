" ftplugin/matlab_mat.vim
if exists("b:did_ftplugin_matlab_mat")
  finish
endif
let b:did_ftplugin_matlab_mat = 1

" Special handling for .mat files
setlocal buftype=nowrite
setlocal nomodifiable

" Load Lua functions
lua require('matlab.matfile').load_current_file()
