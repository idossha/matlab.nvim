-- MATLAB.nvim configuration module
local M = {}

-- Default configuration
M.defaults = {
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

-- Validate and apply user configuration
function M.apply(user_config)
  user_config = user_config or {}
  
  -- Deep merge user config with defaults
  return vim.tbl_deep_extend('force', M.defaults, user_config)
end

return M
