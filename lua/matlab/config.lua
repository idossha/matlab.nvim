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
  debug_features = {
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
    doc = 'h',            -- Show documentation for word under cursor
    toggle_workspace = 'w', -- Show workspace variables (whos)
    clear_workspace = 'x', -- Clear MATLAB workspace
    save_workspace = 's',  -- Save MATLAB workspace to .mat file
    load_workspace = 'l',  -- Load MATLAB workspace from .mat file
    toggle_cell_fold = 'f', -- Toggle current cell fold
    toggle_all_cell_folds = 'F', -- Toggle all cell folds
    open_in_gui = 'g',     -- Open current script in MATLAB GUI
    -- Debug mappings (all under <Leader>md prefix)
    debug_start = 's',   -- Start debugging session
    debug_stop = 'q',    -- Stop debugging session (quit)
    debug_continue = 'c', -- Continue execution
    debug_step_over = 'o', -- Step over
    debug_step_into = 'i', -- Step into
    debug_step_out = 't', -- Step out
    debug_toggle_breakpoint = 'b', -- Toggle breakpoint
    debug_clear_breakpoints = 'B', -- Clear all breakpoints
    debug_eval = 'e',              -- Evaluate expression
    -- Debug UI mappings
    debug_ui = 'u',                -- Show debug control bar
    debug_ui_variables = 'v',      -- Show variables window (auto-updating)
    debug_ui_callstack = 'k',      -- Show call stack window (stack)
    debug_ui_breakpoints = 'p',    -- Show breakpoints window
    debug_ui_repl = 'r',           -- Show REPL window
    debug_ui_show_all = 'a',       -- Show all debug windows
    debug_ui_close = 'Q',          -- Close all debug UI windows (Quit UI)
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
