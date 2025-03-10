if exists('g:loaded_matlab_nvim')
  finish
endif
let g:loaded_matlab_nvim = 1

" Ensure proper filetype detection for MATLAB files
augroup matlab_filetype_detection
  autocmd!
  autocmd BufRead,BufNewFile *.m set filetype=matlab
augroup END

" Enable debugging if set in init.vim/init.lua
if exists('g:matlab_debug') && g:matlab_debug
  echom "MATLAB.nvim: Debug mode enabled"
endif

" Load Lua functionality
lua require('matlab').setup({})

" Add a command to debug keymap issues
command! -nargs=0 MatlabDebugKeymaps call s:DebugKeymaps()

function! s:DebugKeymaps()
  echo "MATLAB Keymap Debug Info:"
  echo "Leader key: '" . mapleader . "'"
  echo "Current filetype: " . &filetype
  echo "Checking for matlab.lua plugin file..."
  let ftplugin_path = findfile('ftplugin/matlab.lua', &rtp)
  if empty(ftplugin_path)
    echo "  - Not found!"
  else
    echo "  - Found at: " . ftplugin_path
  endif
  
  echo "\nTrying to set direct keymaps..."
  nnoremap <buffer> <space>mr :echo "Direct space-mr mapping works!"<CR>
  nnoremap <buffer> <Leader>mr :echo "Direct leader-mr mapping works!"<CR>
  echo "Direct keymaps set for testing. Try pressing <space>mr or <Leader>mr"
endfunction