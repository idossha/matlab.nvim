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
  debug = false,         -- Enable debug logging
  minimal_notifications = true, -- Only show important notifications (server start/stop and errors)
  tmux_pane_direction = 'right', -- Position of the tmux pane ('right', 'below')
  tmux_pane_focus = true,       -- Make tmux pane visible when created
  force_nogui_with_breakpoints = true, -- Prevent MATLAB GUI from opening when breakpoints exist
  
  -- Environment variables to set before starting MATLAB
  environment = {},       -- Table of environment variables: {VAR_NAME = 'value', ANOTHER_VAR = 'another_value'}
  
  breakpoint = {
    sign_text = '■', -- Character to use for breakpoint sign
    sign_hl = 'MatlabBreakpoint', -- Highlight group for the sign
    line_hl = 'MatlabBreakpointLine', -- Highlight group for the entire line
    num_hl = 'MatlabBreakpoint', -- Highlight group for the line number
  },

  -- Debug configuration
  debug = {
    enabled = true, -- Enable debugging features
    auto_update_ui = true, -- Automatically update debug UI indicators
    show_debug_status = true, -- Show debug status in status line
  },

  -- Debug UI configuration
  debug_ui = {
    variables_position = 'right',   -- Position of variables window ('left', 'right', 'top', 'bottom')
    variables_size = 0.3,           -- Size of variables window (0.0-1.0)
    callstack_position = 'bottom',  -- Position of call stack window
    callstack_size = 0.3,           -- Size of call stack window
    breakpoints_position = 'left',  -- Position of breakpoints window
    breakpoints_size = 0.25,        -- Size of breakpoints window
    repl_position = 'bottom',       -- Position of REPL window
    repl_size = 0.4,                -- Size of REPL window
  },

  -- Default keymappings with leader-m prefix
  mappings = {
    prefix = '<Leader>m', -- Common prefix for all MATLAB mappings
    run = 'r',            -- Run MATLAB script
    run_cell = 'c',       -- Run current MATLAB cell
    run_to_cell = 't',    -- Run to current MATLAB cell
    breakpoint = 'b',     -- Set breakpoint at current line
    clear_breakpoint = 'd', -- Clear breakpoint in current file
    clear_breakpoints = 'D', -- Clear all breakpoints
    doc = 'h',            -- Show documentation for word under cursor
    toggle_workspace = 'w', -- Show workspace variables (whos)
    clear_workspace = 'x', -- Clear MATLAB workspace
    save_workspace = 's',  -- Save MATLAB workspace to .mat file
    load_workspace = 'l',  -- Load MATLAB workspace from .mat file
    toggle_cell_fold = 'f', -- Toggle current cell fold
    toggle_all_cell_folds = 'F', -- Toggle all cell folds
    open_in_gui = 'g',     -- Open current script in MATLAB GUI
    -- Debug mappings
    debug_start = 'ds',   -- Start debugging session
    debug_stop = 'de',    -- Stop debugging session
    debug_continue = 'dc', -- Continue execution
    debug_step_over = 'do', -- Step over
    debug_step_into = 'di', -- Step into
    debug_step_out = 'dt', -- Step out
    debug_toggle_breakpoint = 'db', -- Toggle breakpoint
    debug_clear_breakpoints = 'dd', -- Clear all breakpoints
    debug_ui = 'du',     -- Show debug UI
    -- Debug UI mappings
    debug_show_variables = 'dv',    -- Show variables window
    debug_show_callstack = 'dk',    -- Show call stack window
    debug_show_breakpoints = 'dp',  -- Show breakpoints window
    debug_show_repl = 'dr',         -- Show REPL window
    debug_toggle_variables = 'tv',  -- Toggle variables window
    debug_toggle_callstack = 'tk',  -- Toggle call stack window
    debug_toggle_breakpoints = 'tp', -- Toggle breakpoints window
    debug_toggle_repl = 'tr',       -- Toggle REPL window
    debug_close_ui = 'dx',          -- Close all debug UI windows
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
