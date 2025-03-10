-- Main module for matlab.nvim
local M = {}

local config = require('matlab.config')
local tmux = require('matlab.tmux')
local commands = require('matlab.commands')
local cells = require('matlab.cells')
local workspace = require('matlab.workspace')

-- Setup function
function M.setup(opts)
  -- Initialize configuration
  config.setup(opts)
  
  -- Show message on first load only if minimal notifications are disabled
  vim.schedule(function()
    if not config.get('minimal_notifications') then
      vim.notify("matlab.nvim loaded successfully. Use :MatlabStartServer to start MATLAB.", vim.log.levels.INFO)
    end
  end)
  
  -- Create user commands
  vim.api.nvim_create_user_command('MatlabRun', function(args)
    commands.run(args.args ~= '' and args.args or nil)
  end, { nargs = '?' })
  
  vim.api.nvim_create_user_command('MatlabBreakpoint', function()
    commands.single_breakpoint()
  end, {})
  
  vim.api.nvim_create_user_command('MatlabStartServer', function()
    tmux.start_server(false)
  end, {})
  
  vim.api.nvim_create_user_command('MatlabAutoStartServer', function()
    tmux.start_server(true)
  end, {})
  
  vim.api.nvim_create_user_command('MatlabStopServer', function()
    tmux.stop_server()
  end, {})
  
  vim.api.nvim_create_user_command('MatlabClearBreakpoint', function()
    commands.clear_breakpoint(false)
  end, {})
  
  vim.api.nvim_create_user_command('MatlabClearBreakpoints', function()
    commands.clear_breakpoint(true)
  end, {})
  
  vim.api.nvim_create_user_command('MatlabDoc', function()
    commands.doc()
  end, {})
  
  vim.api.nvim_create_user_command('MatlabDocumentation', function()
    commands.doc()
  end, {})
  
  -- Cell execution commands
  vim.api.nvim_create_user_command('MatlabRunCell', function()
    cells.execute_current_cell()
  end, {})
  
  vim.api.nvim_create_user_command('MatlabRunToCell', function()
    cells.execute_to_cell()
  end, {})
  
  -- Cell folding commands
  vim.api.nvim_create_user_command('MatlabToggleCellFold', function()
    cells.toggle_cell_fold()
  end, {})
  
  vim.api.nvim_create_user_command('MatlabToggleAllCellFolds', function()
    cells.toggle_all_cell_folds()
  end, {})
  
  -- Workspace commands
  vim.api.nvim_create_user_command('MatlabWorkspace', function()
    workspace.show()
  end, {})
  
  vim.api.nvim_create_user_command('MatlabToggleWorkspace', function()
    workspace.toggle()
  end, {})
  
  vim.api.nvim_create_user_command('MatlabClearWorkspace', function()
    workspace.clear()
  end, {})
  
  vim.api.nvim_create_user_command('MatlabSaveWorkspace', function(args)
    workspace.save(args.args ~= '' and args.args or nil)
  end, { nargs = '?' })
  
  vim.api.nvim_create_user_command('MatlabLoadWorkspace', function(args)
    workspace.load(args.args ~= '' and args.args or nil)
  end, { nargs = '?' })
  
  -- Command to apply/reapply keymappings to current buffer
  vim.api.nvim_create_user_command('MatlabApplyKeymappings', function()
    M.apply_keymappings()
  end, {})
  
  -- Set up autocommands
  vim.api.nvim_create_augroup('matlab_nvim', { clear = true })
  
  -- Autostart MATLAB when opening a .m file
  vim.api.nvim_create_autocmd('FileType', {
    group = 'matlab_nvim',
    pattern = 'matlab',
    callback = function()
      vim.cmd('MatlabAutoStartServer')
      
      -- Apply keymappings
      M.apply_keymappings()
    end,
  })
  
  -- Stop MATLAB when exiting Neovim
  vim.api.nvim_create_autocmd('VimLeave', {
    group = 'matlab_nvim',
    callback = function()
      vim.cmd('MatlabStopServer')
    end,
  })
end

-- Function to apply keymappings to the current buffer
function M.apply_keymappings()
  if vim.bo.filetype ~= 'matlab' then
    vim.notify("Current buffer is not a MATLAB file", vim.log.levels.WARN)
    return
  end
  
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
    
    vim.notify("MATLAB keymappings applied to current buffer", vim.log.levels.INFO)
  else
    vim.notify("Default mappings are disabled in configuration", vim.log.levels.WARN)
  end
end

-- Export submodules
M.commands = commands
M.cells = cells
M.workspace = workspace
M.tmux = tmux
M.config = config

return M