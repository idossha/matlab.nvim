-- Tmux integration for matlab.nvim
local M = {}
local config = require('matlab.config')

-- Store the server pane ID
M.server_pane = nil

-- Custom notification function that can be set from init.lua
local external_notify_fn = nil

-- Function to set the notification function from outside
function M.set_notify_function(fn)
  external_notify_fn = fn
end

-- Enhanced notification function with better control over what's displayed
function M.notify(message, level, force)
  level = level or vim.log.levels.INFO
  
  -- Use external notification function if available
  if external_notify_fn and type(external_notify_fn) == "function" then
    external_notify_fn(message, level, force)
    return
  end
  
  -- Always show errors
  if level == vim.log.levels.ERROR then
    vim.notify(message, level)
    return
  end
  
  -- For debug messages, only show if debug is enabled
  if level == vim.log.levels.DEBUG and not config.get('debug') then
    -- Still log to file even if not showing notification
    local log_file = io.open(vim.fn.stdpath('cache') .. '/matlab_nvim.log', 'a')
    if log_file then
      log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " [DEBUG] - " .. message .. "\n")
      log_file:close()
    end
    return
  end
  
  -- When minimal_notifications is enabled, only show explicitly forced messages
  if config.get('minimal_notifications') and not force then
    -- Stricter filter for important notifications
    local important_messages = {
      'MATLAB server started.',
      'Stopping MATLAB server.',
      'MATLAB executable not found'
    }
    
    local is_important = false
    for _, important_msg in ipairs(important_messages) do
      if message:find(important_msg, 1, true) then -- Use exact matching
        is_important = true
        break
      end
    end
    
    if not is_important then
      -- Log to file instead of notifying
      local log_file = io.open(vim.fn.stdpath('cache') .. '/matlab_nvim.log', 'a')
      if log_file then
        log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. message .. "\n")
        log_file:close()
      end
      return
    end
  end
  
  -- Default: show the notification
  vim.notify(message, level)
end

-- Check if tmux exists and we're in a tmux session
function M.exists()
  -- First check if the tmux command is available
  if vim.fn.executable('tmux') ~= 1 then
    M.notify('tmux command not found. Please make sure tmux is installed.', vim.log.levels.ERROR)
    return false
  end
  
  -- Check if we're inside a tmux session
  if vim.env.TMUX == nil or vim.env.TMUX == '' then
    -- Additional check: try running tmux directly to see if it works
    local tmux_version = vim.fn.system('tmux -V')
    if vim.v.shell_error == 0 then
      M.notify('tmux is installed, but you are not inside a tmux session. Please start tmux first.', vim.log.levels.ERROR)
    else
      M.notify('matlab.nvim cannot run without tmux.', vim.log.levels.ERROR)
    end
    return false
  end
  
  return true
end

-- Execute a tmux command
function M.execute(command)
  local cmd = 'tmux ' .. command
  
  if config.get('debug') then
    M.notify('Executing tmux command: ' .. cmd, vim.log.levels.DEBUG)
  end
  
  -- Use pcall to catch any errors in system command execution
  local success, output = pcall(vim.fn.system, cmd)
  
  if not success then
    M.notify('Error executing tmux command: ' .. cmd, vim.log.levels.ERROR, true)
    M.notify('Error details: ' .. tostring(output), vim.log.levels.DEBUG)
    return ""
  end
  
  -- Check shell error code
  if vim.v.shell_error ~= 0 then
    if config.get('debug') then
      M.notify('Tmux command returned non-zero exit code: ' .. vim.v.shell_error, vim.log.levels.DEBUG)
      M.notify('Command output: ' .. output, vim.log.levels.DEBUG)
    end
  end
  
  return output
end

-- Check if the pane exists
function M.pane_exists()
  if not M.server_pane then
    return false
  end
  
  local result = M.execute('has-session -t ' .. vim.fn.shellescape(M.server_pane))
  return vim.v.shell_error == 0
end

-- Get the server pane
function M.get_server_pane()
  if M.pane_exists() then
    return M.server_pane
  end

  -- Search for existing MATLAB pane inside the current window
  local cmd = 'list-panes -F "#{session_id}:#{window_id}.#{pane_id}-#{pane_start_command}"'
  local views = vim.split(M.execute(cmd), '\n')

  for _, view in ipairs(views) do
    -- Check if the start command contains matlab (case-insensitive)
    if view:lower():match('matlab') then
      M.server_pane = view:match('([^-]+)')
      return M.server_pane
    end
  end

  return nil
end

-- Open the MATLAB pane
function M.open_pane()
  local pane = M.get_server_pane()
  if pane then
    return M.execute('select-pane -t .' .. pane)
  end
  return nil
end

-- Run a command in the MATLAB pane
function M.run(command, skip_interrupt)
  local target = M.get_server_pane()

  if target then
    -- Send control-c to abort any running command except when it is disabled
    if not skip_interrupt then
      M.execute("send-keys -t " .. vim.fn.shellescape(target) .. " C-c")
    end

    local cmd = vim.fn.escape(command, '"')
    local r = M.execute("send-keys -t " .. vim.fn.shellescape(target) .. " " .. vim.fn.shellescape(cmd))
    M.execute("send-keys -t " .. vim.fn.shellescape(target) .. " Enter")
    return r
  else
    vim.ui.select({'Yes', 'No'}, {
      prompt = 'MATLAB pane could not be found. Start MATLAB?'
    }, function(choice)
      if choice == 'Yes' then
        -- Start server and run current command
        M.start_server(false, vim.fn.escape(command, '"'))
        -- Dismiss the "Press ENTER to continue" message
        M.execute('send-keys Enter')
      end
    end)
  end
  
  return nil
end

-- Get the project root directory
function M.get_project_root()
  local dir = vim.fn.getcwd()
  
  -- Check if there is a folder like matlab or matlab-code
  local paths = vim.fn.glob(dir .. '/matlab*', false, true)
  for _, path in ipairs(paths) do
    if vim.fn.isdirectory(path) == 1 then
      return path
    end
  end
  
  return dir
end

-- Find MATLAB executable across different OS versions
function M.find_matlab_executable()
  local function check_and_notify(path)
    if vim.fn.filereadable(path) == 1 then
      M.notify('Found MATLAB at: ' .. path, vim.log.levels.INFO)
      M.notify('Update your configuration with: require("matlab").setup({executable = "' .. path .. '"})', vim.log.levels.INFO)
      return path
    end
    return nil
  end

  -- Generate a list of possible MATLAB versions
  local versions = {}
  local current_year = tonumber(os.date('%Y'))
  for year = current_year, current_year - 5, -1 do
    table.insert(versions, 'R' .. year .. 'a')
    table.insert(versions, 'R' .. year .. 'b')
  end
  
  -- Generate platform-specific MATLAB paths
  local matlab_paths = {}
  
  -- macOS paths
  if vim.fn.has('mac') == 1 then
    for _, version in ipairs(versions) do
      table.insert(matlab_paths, '/Applications/MATLAB_' .. version .. '.app/bin/matlab')
    end
  -- Linux paths
  elseif vim.fn.has('unix') == 1 and not vim.fn.has('mac') == 1 then
    for _, version in ipairs(versions) do
      table.insert(matlab_paths, '/usr/local/MATLAB/' .. version .. '/bin/matlab')
      table.insert(matlab_paths, '/opt/MATLAB/' .. version .. '/bin/matlab')
      table.insert(matlab_paths, vim.fn.expand('~/MATLAB/' .. version .. '/bin/matlab'))
    end
  -- Windows paths
  elseif vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
    for _, version in ipairs(versions) do
      table.insert(matlab_paths, 'C:\\Program Files\\MATLAB\\' .. version .. '\\bin\\matlab.exe')
      table.insert(matlab_paths, 'C:\\Program Files (x86)\\MATLAB\\' .. version .. '\\bin\\matlab.exe')
    end
  end
  
  -- Check each path
  for _, path in ipairs(matlab_paths) do
    local found = check_and_notify(path)
    if found then
      return found
    end
  end
  
  return nil
end

-- Check if MATLAB executable exists
function M.check_matlab_executable()
  local executable = config.get('executable')
  
  -- If it's a valid executable, we're good
  if vim.fn.executable(executable) == 1 then
    return true
  end
  
  -- Try to find MATLAB in common locations
  local found_matlab = M.find_matlab_executable()
  
  -- If we found it, suggest using that path
  if found_matlab then
    -- Store it so this session works
    config.options.executable = found_matlab
    return true
  end
  
  -- Couldn't find MATLAB - provide helpful error with OS-specific suggestions
  M.notify('MATLAB executable not found: ' .. executable, vim.log.levels.ERROR, true)
  
  local help_msg
  if vim.fn.has('mac') == 1 then
    help_msg = 'require("matlab").setup({executable = "/Applications/MATLAB_R2024a.app/bin/matlab"})'
  elseif vim.fn.has('unix') == 1 then
    help_msg = 'require("matlab").setup({executable = "/usr/local/MATLAB/R2024a/bin/matlab"})'
  elseif vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
    help_msg = 'require("matlab").setup({executable = "C:\\\\Program Files\\\\MATLAB\\\\R2024a\\\\bin\\\\matlab.exe"})'
  else
    help_msg = 'require("matlab").setup({executable = "/path/to/matlab"})'
  end
  
  M.notify('Please specify the full path to MATLAB in your config: ' .. help_msg, vim.log.levels.WARN, true)
  return false
end

-- Check if a system command is available
function M.command_exists(cmd)
  if type(cmd) ~= "string" then return false end
  
  -- Using vim's executable() function is more reliable
  return vim.fn.executable(cmd) == 1
end

-- Build platform-specific MATLAB startup command
function M.build_matlab_command(executable, startup_cmd)
  local base_command = executable .. ' -nodesktop -nosplash'
  
  -- Different platforms have different command line argument formats
  if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
    -- Windows uses /r instead of -r
    return base_command .. ' /r ' .. vim.fn.shellescape(startup_cmd)
  else
    -- macOS and Linux use -r
    return base_command .. ' -r ' .. vim.fn.shellescape(startup_cmd)
  end
end

-- Validate UI settings to ensure they're valid
function M.validate_ui_settings()
  -- Validate panel size
  local panel_size = config.get('panel_size')
  if type(panel_size) ~= "number" or panel_size <= 0 then
    M.notify('Invalid panel_size: ' .. tostring(panel_size) .. '. Using default of 50', vim.log.levels.WARN)
    config.options.panel_size = 50
  end
  
  -- Validate panel size type
  local panel_size_type = config.get('panel_size_type')
  if panel_size_type ~= 'percentage' and panel_size_type ~= 'fixed' then
    M.notify('Invalid panel_size_type: ' .. tostring(panel_size_type) .. '. Using "percentage"', vim.log.levels.WARN)
    config.options.panel_size_type = 'percentage'
  end
  
  -- Validate pane direction
  local direction = config.get('tmux_pane_direction')
  if direction ~= 'right' and direction ~= 'below' then
    M.notify('Invalid tmux_pane_direction: ' .. tostring(direction) .. '. Using "right"', vim.log.levels.WARN)
    config.options.tmux_pane_direction = 'right'
  end
  
  -- Log current settings if debug is enabled
  if config.get('debug') then
    M.notify('UI Settings:', vim.log.levels.DEBUG)
    M.notify('- panel_size: ' .. tostring(config.get('panel_size')), vim.log.levels.DEBUG)
    M.notify('- panel_size_type: ' .. tostring(config.get('panel_size_type')), vim.log.levels.DEBUG)
    M.notify('- tmux_pane_direction: ' .. tostring(config.get('tmux_pane_direction')), vim.log.levels.DEBUG)
    M.notify('- tmux_pane_focus: ' .. tostring(config.get('tmux_pane_focus')), vim.log.levels.DEBUG)
  end
end

-- Start the MATLAB server
function M.start_server(auto_start, startup_command)
  if config.get('debug') then
    M.notify('Starting MATLAB server (auto_start=' .. tostring(auto_start) .. ')', vim.log.levels.DEBUG)
  end
  
  -- Check for tmux environment (includes command existence check)
  if not M.exists() then
    return
  end

  -- Check if autostart is enabled
  if auto_start and not config.get('auto_start') then
    M.notify('Auto-start is disabled in config', vim.log.levels.DEBUG)
    return
  end
  
  -- Verify MATLAB executable exists
  if not M.check_matlab_executable() then
    return
  end

  -- Validate UI settings before using them
  M.validate_ui_settings()

  if not M.get_server_pane() then
    -- Create new pane, start matlab in it and save its id
    local project_root = M.get_project_root()
    M.notify('Project root: ' .. project_root, vim.log.levels.DEBUG)
    local startup_cmd = 'cd ' .. vim.fn.shellescape(project_root) .. ';'
    
    -- Add command to startup if provided
    if startup_command then
      startup_cmd = startup_cmd .. startup_command .. ';'
      M.notify('Adding startup command: ' .. startup_command, vim.log.levels.DEBUG)
    end

    local executable = config.get('executable')
    M.notify('Using MATLAB executable: ' .. executable, vim.log.levels.DEBUG)
    
    -- Build the MATLAB startup command with platform-specific adjustments
    local mlcmd = 'clear && ' .. M.build_matlab_command(executable, startup_cmd)
    
    -- Create tmux split with the MATLAB command
    local split_flags = ""
    
    -- Set pane direction based on configuration
    local direction = config.get('tmux_pane_direction')
    if direction == 'right' then
      split_flags = "-h" -- horizontal split (side by side)
    else
      split_flags = "-v" -- vertical split (top/bottom)
    end
    
    -- Add -d flag if we don't want to focus the new pane
    if not config.get('tmux_pane_focus') then
      split_flags = split_flags .. "d"
    end
    
    local cmd = 'split-window ' .. split_flags .. ' -PF "#{session_id}:#{window_id}.#{pane_id}" ' .. vim.fn.shellescape(mlcmd)
    
    M.notify('Creating MATLAB pane with command: ' .. cmd, vim.log.levels.DEBUG)
    local result = M.execute(cmd)
    M.notify('Tmux command result: ' .. vim.inspect(result), vim.log.levels.DEBUG)
    
    M.server_pane = result:gsub('[^%%$@%.:0-9]', '')
    M.notify('Extracted pane ID: ' .. tostring(M.server_pane), vim.log.levels.DEBUG)

    if M.pane_exists() then
      M.notify('MATLAB server started.', vim.log.levels.INFO, true)
    else
      M.notify('Something went wrong starting the MATLAB server.', vim.log.levels.ERROR, true)
      M.notify('Check that MATLAB is properly installed and the executable path is correct.', vim.log.levels.WARN, true)
      M.notify('Current executable path: ' .. executable, vim.log.levels.WARN)
      return
    end

    -- Set pane size with delay to ensure it's applied correctly
    local panel_size = config.get('panel_size')
    local panel_size_type = config.get('panel_size_type')
    
    M.notify('Setting panel size to: ' .. panel_size .. 
             (panel_size_type == 'percentage' and '%' or ' columns'), vim.log.levels.DEBUG)
    
    -- Add a delay to ensure tmux pane is ready before resizing
    vim.defer_fn(function()
      if M.server_pane and M.pane_exists() then
        if panel_size_type == 'percentage' then
          -- Use percentage of the screen
          M.execute("resize-pane -t " .. vim.fn.shellescape(M.server_pane) .. " -p " .. tostring(panel_size))
          
          -- Double-check after a brief delay in case the first resize didn't take
          vim.defer_fn(function()
            M.execute("resize-pane -t " .. vim.fn.shellescape(M.server_pane) .. " -p " .. tostring(panel_size))
          end, 200)
        else
          -- Use fixed width
          M.execute("resize-pane -t " .. vim.fn.shellescape(M.server_pane) .. " -x " .. tostring(panel_size))
          
          -- Double-check after a brief delay
          vim.defer_fn(function()
            M.execute("resize-pane -t " .. vim.fn.shellescape(M.server_pane) .. " -x " .. tostring(panel_size))
          end, 200)
        end
      end
    end, 500) -- 500ms delay to ensure tmux pane is fully created

    -- Zoom current pane if we don't want the MATLAB pane to be visible
    if not config.get('tmux_pane_focus') then
      M.notify('Zooming current pane', vim.log.levels.DEBUG)
      M.execute('resize-pane -Z')
    end
  else
    M.notify('MATLAB server pane already exists', vim.log.levels.DEBUG)
  end
end

-- Stop the MATLAB server
function M.stop_server()
  if not M.exists() or not M.server_pane then
    return
  end

  if M.get_server_pane() then
    M.notify('Stopping MATLAB server.', vim.log.levels.INFO, true)
    M.run('quit')
    M.server_pane = nil
  end
end

return M
