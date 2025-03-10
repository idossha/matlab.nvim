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
  
  -- Set up autocommands
  vim.api.nvim_create_augroup('matlab_nvim', { clear = true })
  
  -- Autostart MATLAB when opening a .m file
  vim.api.nvim_create_autocmd('FileType', {
    group = 'matlab_nvim',
    pattern = 'matlab',
    callback = function()
      vim.cmd('MatlabAutoStartServer')
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


-- Export submodules
M.commands = commands
M.cells = cells
M.workspace = workspace
M.tmux = tmux
M.config = config

return M