-- Utility functions for matlab.nvim
local M = {}
local config = nil

-- Lazy load config to avoid circular dependencies
local function get_config()
  if not config then
    config = require('matlab.config')
  end
  return config
end

-- Centralized notification function with logging and filtering
function M.notify(message, level, force)
  level = level or vim.log.levels.INFO
  
  -- Always show errors
  if level == vim.log.levels.ERROR then
    vim.notify(message, level)
    M.log(message, 'ERROR')
    return
  end
  
  local cfg = get_config()
  
  -- For debug messages, only show if debug is enabled
  if level == vim.log.levels.DEBUG and not cfg.get('debug') then
    M.log(message, 'DEBUG')
    return
  end
  
  -- When minimal_notifications is enabled, only show forced messages or important ones
  if cfg.get('minimal_notifications') and not force then
    local important_patterns = {
      'MATLAB server started',
      'Stopping MATLAB server',
      'MATLAB executable not found',
      'tmux.*not found',
      'not inside a tmux session'
    }
    
    local is_important = false
    for _, pattern in ipairs(important_patterns) do
      if message:match(pattern) then
        is_important = true
        break
      end
    end
    
    if not is_important then
      M.log(message, level == vim.log.levels.WARN and 'WARN' or 'INFO')
      return
    end
  end
  
  -- Show the notification
  vim.notify(message, level)
  M.log(message, level == vim.log.levels.WARN and 'WARN' or 'INFO')
end

-- Log to file for debugging
function M.log(message, level_str)
  level_str = level_str or 'INFO'
  local log_file = io.open(vim.fn.stdpath('cache') .. '/matlab_nvim.log', 'a')
  if log_file then
    log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " [" .. level_str .. "] - " .. message .. "\n")
    log_file:close()
  end
end

return M

