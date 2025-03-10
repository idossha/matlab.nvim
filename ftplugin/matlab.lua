-- ftplugin for MATLAB files

-- Only load this plugin once per buffer
if vim.b.did_ftplugin_matlab_nvim then
  return
end
vim.b.did_ftplugin_matlab_nvim = true

local config = require('matlab.config')

-- Set up key mappings if enabled in config
if config.get('default_mappings') then
  local mappings = config.get('mappings')
  local prefix = mappings.prefix or '<Leader>m'
  
  -- Run commands
  vim.keymap.set('n', prefix .. mappings.run, '<Cmd>MatlabRun<CR>', { buffer = true, desc = 'Run MATLAB script' })
  vim.keymap.set('n', prefix .. mappings.run_cell, '<Cmd>MatlabRunCell<CR>', { buffer = true, desc = 'Run current MATLAB cell' })
  vim.keymap.set('n', prefix .. mappings.run_to_cell, '<Cmd>MatlabRunToCell<CR>', { buffer = true, desc = 'Run to current MATLAB cell' })

  -- Breakpoints
  vim.keymap.set('n', prefix .. mappings.breakpoint, '<Cmd>MatlabBreakpoint<CR>', { buffer = true, desc = 'Set MATLAB breakpoint' })
  vim.keymap.set('n', prefix .. mappings.clear_breakpoint, '<Cmd>MatlabClearBreakpoint<CR>', { buffer = true, desc = 'Clear MATLAB breakpoint' })
  vim.keymap.set('n', prefix .. mappings.clear_breakpoints, '<Cmd>MatlabClearBreakpoints<CR>', { buffer = true, desc = 'Clear all MATLAB breakpoints' })

  -- Documentation
  vim.keymap.set('n', prefix .. mappings.doc, '<Cmd>MatlabDoc<CR>', { buffer = true, desc = 'Show MATLAB documentation' })

  -- Workspace
  vim.keymap.set('n', prefix .. mappings.toggle_workspace, '<Cmd>MatlabToggleWorkspace<CR>', { buffer = true, desc = 'Toggle MATLAB workspace window' })
  vim.keymap.set('n', prefix .. mappings.show_workspace, '<Cmd>MatlabWorkspace<CR>', { buffer = true, desc = 'Show MATLAB workspace in tmux' })
  vim.keymap.set('n', prefix .. mappings.clear_workspace, '<Cmd>MatlabClearWorkspace<CR>', { buffer = true, desc = 'Clear MATLAB workspace' })
  vim.keymap.set('n', prefix .. mappings.save_workspace, '<Cmd>MatlabSaveWorkspace<CR>', { buffer = true, desc = 'Save MATLAB workspace' })
  vim.keymap.set('n', prefix .. mappings.load_workspace, '<Cmd>MatlabLoadWorkspace<CR>', { buffer = true, desc = 'Load MATLAB workspace' })
  
  -- Cell folding
  vim.keymap.set('n', prefix .. mappings.toggle_cell_fold, '<Cmd>MatlabToggleCellFold<CR>', { buffer = true, desc = 'Toggle current MATLAB cell fold' })
  vim.keymap.set('n', prefix .. mappings.toggle_all_cell_folds, '<Cmd>MatlabToggleAllCellFolds<CR>', { buffer = true, desc = 'Toggle all MATLAB cell folds' })
end