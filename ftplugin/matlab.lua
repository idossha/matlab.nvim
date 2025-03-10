-- ftplugin for MATLAB files

-- Only load this plugin once per buffer
if vim.b.did_ftplugin_matlab_nvim then
  return
end
vim.b.did_ftplugin_matlab_nvim = true

local config = require('matlab.config')

-- Set up key mappings if enabled in config
if config.get('default_mappings') then
  -- Run commands
  vim.keymap.set('n', '<Leader>mr', '<Cmd>MatlabRun<CR>', { buffer = true, desc = 'Run MATLAB script' })
  vim.keymap.set('n', '<Leader>mc', '<Cmd>MatlabRunCell<CR>', { buffer = true, desc = 'Run current MATLAB cell' })
  vim.keymap.set('n', '<Leader>mt', '<Cmd>MatlabRunToCell<CR>', { buffer = true, desc = 'Run to current MATLAB cell' })

  -- Breakpoints
  vim.keymap.set('n', '<Leader>mb', '<Cmd>MatlabBreakpoint<CR>', { buffer = true, desc = 'Set MATLAB breakpoint' })
  vim.keymap.set('n', '<Leader>md', '<Cmd>MatlabClearBreakpoint<CR>', { buffer = true, desc = 'Clear MATLAB breakpoint' })
  vim.keymap.set('n', '<Leader>mD', '<Cmd>MatlabClearBreakpoints<CR>', { buffer = true, desc = 'Clear all MATLAB breakpoints' })

  -- Documentation
  vim.keymap.set('n', '<Leader>mh', '<Cmd>MatlabDoc<CR>', { buffer = true, desc = 'Show MATLAB documentation' })

  -- Workspace
  vim.keymap.set('n', '<Leader>mw', '<Cmd>MatlabToggleWorkspace<CR>', { buffer = true, desc = 'Toggle MATLAB workspace window' })
  vim.keymap.set('n', '<Leader>mW', '<Cmd>MatlabWorkspace<CR>', { buffer = true, desc = 'Show MATLAB workspace in tmux' })
  vim.keymap.set('n', '<Leader>mx', '<Cmd>MatlabClearWorkspace<CR>', { buffer = true, desc = 'Clear MATLAB workspace' })
  vim.keymap.set('n', '<Leader>ms', '<Cmd>MatlabSaveWorkspace<CR>', { buffer = true, desc = 'Save MATLAB workspace' })
  vim.keymap.set('n', '<Leader>ml', '<Cmd>MatlabLoadWorkspace<CR>', { buffer = true, desc = 'Load MATLAB workspace' })
  
  -- Cell folding
  vim.keymap.set('n', '<Leader>mf', '<Cmd>MatlabToggleCellFold<CR>', { buffer = true, desc = 'Toggle current MATLAB cell fold' })
  vim.keymap.set('n', '<Leader>mF', '<Cmd>MatlabToggleAllCellFolds<CR>', { buffer = true, desc = 'Toggle all MATLAB cell folds' })
end