-- Configuration for matlab.nvim
-- lua/matlab/config.lua
local M = {}

-- Default configuration
M.defaults = {
  executable = 'matlab',  -- MATLAB executable (can be full path if MATLAB is not in PATH)
  panel_size = 30,        -- Size in percentage (%) of the terminal width
  panel_size_type = 'percentage', -- 'percentage' or 'fixed' (fixed = columns)
  auto_start = true,
  default_mappings = true,
  minimal_notifications = true, -- Only show important notifications (server start/stop and errors)
  tmux_pane_direction = 'right', -- Position of the tmux pane ('right', 'below')
  tmux_pane_focus = true,       -- Make tmux pane visible when created

  -- Environment variables to set before starting MATLAB
  environment = {},       -- Table of environment variables: {VAR_NAME = 'value', ANOTHER_VAR = 'another_value'}

  -- Debug and logging configuration
  debug = false,         -- Enable debug logging

  -- Debug UI configuration
  debug_ui = {
    sidebar_width = 40,
    sidebar_position = 'right', -- 'left' or 'right'
  },

  -- Default keymappings
  -- <Leader>m  = MATLAB general commands
  -- <Leader>md = MATLAB debug commands
  mappings = {
    -- General MATLAB commands (<Leader>m + key)
    prefix = '<Leader>m',
    run = 'r',              -- <Leader>mr - Run MATLAB script
    run_cell = 'c',         -- <Leader>mc - Run current cell
    run_to_cell = 'C',      -- <Leader>mC - Run to current cell
    doc = 'h',              -- <Leader>mh - Show documentation
    workspace = 'w',        -- <Leader>mw - Show workspace (whos)
    workspace_pane = 'W',   -- <Leader>mW - Toggle debug UI (with workspace)
    clear_workspace = 'x',  -- <Leader>mx - Clear workspace
    toggle_cell_fold = 'f', -- <Leader>mf - Toggle cell fold
    open_in_gui = 'g',      -- <Leader>mg - Open in MATLAB GUI

    -- Debug commands (<Leader>md + key)
    debug_prefix = 'd',     -- Makes <Leader>md the debug prefix
    debug_start = 's',      -- <Leader>mds - Start debug
    debug_stop = 'q',       -- <Leader>mdq - Stop debug (quit)
    debug_continue = 'c',   -- <Leader>mdc - Continue
    debug_step_over = 'n',  -- <Leader>mdn - Step over (next)
    debug_step_into = 'i',  -- <Leader>mdi - Step into
    debug_step_out = 'o',   -- <Leader>mdo - Step out
    debug_breakpoint = 'b', -- <Leader>mdb - Toggle breakpoint
    debug_clear_bp = 'B',   -- <Leader>mdB - Clear all breakpoints
    debug_eval = 'e',       -- <Leader>mde - Evaluate expression
    debug_ui = 'u',         -- <Leader>mdu - Toggle debug sidebar
  }
}

-- User configuration
M.options = {}

-- Initialize configuration
function M.setup(opts)
  M.options = vim.tbl_deep_extend('force', {}, M.defaults, opts or {})
end

-- Get a specific option value
function M.get(key)
  if M.options[key] ~= nil then
    return M.options[key]
  end
  return M.defaults[key]
end

return M
