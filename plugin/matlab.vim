" plugin/matlab.vim
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

" IMPORTANT: DON'T call setup() here - it overrides user configuration!
" The setup will be called by the user's configuration

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
  
  " Check configuration
  echo "\nCurrent MATLAB configuration:"
  lua << EOF
  local config_ok, config = pcall(require, 'matlab.config')
  if config_ok then
    print("  default_mappings: " .. tostring(config.get('default_mappings')))
    print("  debug: " .. tostring(config.get('debug')))
    print("  minimal_notifications: " .. tostring(config.get('minimal_notifications')))
    print("  tmux_pane_direction: " .. tostring(config.get('tmux_pane_direction')))
    print("  panel_size: " .. tostring(config.get('panel_size')))
  else
    print("  Could not load matlab.config")
  end
EOF
endfunction
