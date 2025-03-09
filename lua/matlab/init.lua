-- MATLAB.nvim - A Neovim plugin for MATLAB development
-- Maintainer: Your Name
-- License: MIT

local M = {}

-- Default configuration
M.config = {
  -- MATLAB executable path (default: tries to find in PATH)
  matlab_executable = 'matlab',
  
  -- Enable cell rendering
  highlight_cells = true,
  
  -- Cell separator appearance
  cell_separator = {
    -- Character to use for separator line
    char = '─',
    -- Length of the separator line (0 = full width)
    length = 0,
  },
  
  -- Workspace viewer settings
  workspace = {
    -- Enable workspace viewer
    enable = true,
    -- Position: 'right', 'left', or 'float'
    position = 'right',
    -- Width of the sidebar (when position is 'right' or 'left')
    width = 40,
    -- Auto-refresh interval in seconds (0 to disable)
    refresh_interval = 5,
  },
  
  -- Keymappings
  mappings = {
    -- Navigate to next cell
    next_cell = ']m',
    -- Navigate to previous cell
    prev_cell = '[m',
    -- Execute current cell
    exec_cell = '<leader>mc',
    -- Execute entire file
    exec_file = '<leader>mf',
    -- Execute current selection
    exec_selection = '<leader>ms',
    -- Toggle workspace viewer
    toggle_workspace = '<leader>mw',
  },
}

-- Set up the plugin with user configuration
function M.setup(opts)
  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend('force', M.config, opts or {})
  
  -- Load modules
  local cells = require('matlab.cells')
  local workspace = require('matlab.workspace')
  local commands = require('matlab.commands')
  
  -- Initialize modules
  cells.setup(M.config)
  workspace.setup(M.config)
  commands.setup(M.config)
  
  -- Create user commands
  M.create_commands()
  
  -- Set up autocommands
  M.create_autocommands()
  
  return M
end

-- Create user commands
function M.create_commands()
  vim.api.nvim_create_user_command('MatlabExecuteCell', function()
    require('matlab.commands').execute_cell()
  end, { desc = 'Execute current MATLAB cell' })
  
  vim.api.nvim_create_user_command('MatlabExecuteFile', function()
    require('matlab.commands').execute_file()
  end, { desc = 'Execute entire MATLAB file' })
  
  vim.api.nvim_create_user_command('MatlabExecuteSelection', function()
    require('matlab.commands').execute_selection()
  end, { desc = 'Execute selected MATLAB code' })
  
  vim.api.nvim_create_user_command('MatlabToggleWorkspace', function()
    require('matlab.workspace').toggle()
  end, { desc = 'Toggle MATLAB workspace viewer' })
  
  vim.api.nvim_create_user_command('MatlabNextCell', function()
    require('matlab.cells').goto_next_cell()
  end, { desc = 'Go to next MATLAB cell' })
  
  vim.api.nvim_create_user_command('MatlabPrevCell', function()
    require('matlab.cells').goto_prev_cell()
  end, { desc = 'Go to previous MATLAB cell' })
end

-- Create autocommands
function M.create_autocommands()
  local group = vim.api.nvim_create_augroup('matlab_nvim', { clear = true })
  
  -- Apply cell highlighting when opening MATLAB files
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    pattern = 'matlab',
    callback = function()
      if M.config.highlight_cells then
        require('matlab.cells').apply_highlighting()
      end
      
      -- Apply keymappings
      M.apply_keymaps()
    end,
  })
  
  -- Refresh highlighting when writing the file
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    pattern = '*.m',
    callback = function()
      if M.config.highlight_cells then
        require('matlab.cells').apply_highlighting()
      end
    end,
  })
end

-- Apply keymappings
function M.apply_keymaps()
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = 0, desc = desc })
  end
  
  local mappings = M.config.mappings
  
  map('n', mappings.next_cell, function() require('matlab.cells').goto_next_cell() end, 'Go to next MATLAB cell')
  map('n', mappings.prev_cell, function() require('matlab.cells').goto_prev_cell() end, 'Go to previous MATLAB cell')
  map('n', mappings.exec_cell, function() require('matlab.commands').execute_cell() end, 'Execute current MATLAB cell')
  map('n', mappings.exec_file, function() require('matlab.commands').execute_file() end, 'Execute entire MATLAB file')
  map('v', mappings.exec_selection, function() require('matlab.commands').execute_selection() end, 'Execute selected MATLAB code')
  map('n', mappings.toggle_workspace, function() require('matlab.workspace').toggle() end, 'Toggle MATLAB workspace viewer')
end

return M
