-- Configuration for matlab.nvim
local M = {}

-- Default configuration
M.defaults = {
  executable = 'matlab',  -- MATLAB executable (can be full path if MATLAB is not in PATH)
  panel_size = 50,        -- Size in percentage (%) of the terminal width
  panel_size_type = 'percentage', -- 'percentage' or 'fixed' (fixed = columns)
  auto_start = true,
  default_mappings = true,
  debug = false,         -- Enable debug logging
  minimal_notifications = false, -- Only show important notifications (server start/stop and errors)
  tmux_pane_direction = 'right', -- Position of the tmux pane ('right', 'below')
  tmux_pane_focus = true,       -- Make tmux pane visible when created
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