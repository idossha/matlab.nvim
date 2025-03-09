-- Tmux integration for matlab.nvim
local M = {}
local config = require('matlab.config')

-- Store the server pane ID
M.server_pane = nil

-- Check if tmux exists
function M.exists()
  if vim.env.TMUX == nil or vim.env.TMUX == '' then
    vim.notify('matlab.nvim cannot run without tmux.', vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Execute a tmux command
function M.execute(command)
  local cmd = 'tmux ' .. command
  vim.notify('Executing tmux command: ' .. cmd, vim.log.levels.DEBUG)
  local output = vim.fn.system(cmd)
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

-- Check if MATLAB executable exists
function M.check_matlab_executable()
  local executable = config.get('executable')
  
  -- If it's a full path, check if the file exists
  if vim.fn.executable(executable) == 1 then
    return true
  end
  
  -- On macOS, also check common MATLAB installation locations
  if vim.fn.has('mac') == 1 then
    local common_paths = {
      '/Applications/MATLAB_R2023b.app/bin/matlab',
      '/Applications/MATLAB_R2023a.app/bin/matlab',
      '/Applications/MATLAB_R2022b.app/bin/matlab',
      '/Applications/MATLAB_R2022a.app/bin/matlab',
      '/Applications/MATLAB_R2021b.app/bin/matlab',
      '/Applications/MATLAB_R2021a.app/bin/matlab',
    }
    
    for _, path in ipairs(common_paths) do
      if vim.fn.filereadable(path) == 1 then
        vim.notify('Found MATLAB at: ' .. path, vim.log.levels.INFO)
        vim.notify('Update your configuration with: require("matlab").setup({executable = "' .. path .. '"})', vim.log.levels.INFO)
        return false
      end
    end
  end
  
  vim.notify('MATLAB executable not found: ' .. executable, vim.log.levels.ERROR)
  vim.notify('Please specify the full path to MATLAB in your config: require("matlab").setup({executable = "/path/to/matlab"})', vim.log.levels.WARN)
  return false
end

-- Start the MATLAB server
function M.start_server(auto_start, startup_command)
  if config.get('debug') then
    vim.notify('Starting MATLAB server (auto_start=' .. tostring(auto_start) .. ')', vim.log.levels.INFO)
  end
  
  if not M.exists() then
    vim.notify('Tmux environment not detected', vim.log.levels.DEBUG)
    return
  end

  -- Check if autostart is enabled
  if auto_start and not config.get('auto_start') then
    vim.notify('Auto-start is disabled in config', vim.log.levels.DEBUG)
    return
  end
  
  -- Verify MATLAB executable exists
  if not M.check_matlab_executable() then
    return
  end

  if not M.get_server_pane() then
    -- Create new pane, start matlab in it and save its id
    local project_root = M.get_project_root()
    vim.notify('Project root: ' .. project_root, vim.log.levels.DEBUG)
    local startup_cmd = 'cd ' .. vim.fn.shellescape(project_root) .. ';'
    
    -- Add command to startup if provided
    if startup_command then
      startup_cmd = startup_cmd .. startup_command .. ';'
      vim.notify('Adding startup command: ' .. startup_command, vim.log.levels.DEBUG)
    end

    local executable = config.get('executable')
    vim.notify('Using MATLAB executable: ' .. executable, vim.log.levels.DEBUG)
    local mlcmd = 'clear && ' .. executable .. ' -nodesktop -nosplash -r ' .. vim.fn.shellescape(startup_cmd)
    local cmd = 'split-window -dhPF "#{session_id}:#{window_id}.#{pane_id}" ' .. vim.fn.shellescape(mlcmd)
    
    vim.notify('Creating MATLAB pane with command: ' .. cmd, vim.log.levels.DEBUG)
    local result = M.execute(cmd)
    vim.notify('Tmux command result: ' .. vim.inspect(result), vim.log.levels.DEBUG)
    
    M.server_pane = result:gsub('[^%%$@%.:0-9]', '')
    vim.notify('Extracted pane ID: ' .. tostring(M.server_pane), vim.log.levels.DEBUG)

    if M.pane_exists() then
      vim.notify('MATLAB server started.', vim.log.levels.INFO)
    else
      vim.notify('Something went wrong starting the MATLAB server.', vim.log.levels.ERROR)
      vim.notify('Check that MATLAB is properly installed and the executable path is correct.', vim.log.levels.WARN)
      vim.notify('Current executable path: ' .. executable, vim.log.levels.WARN)
      return
    end

    -- Set pane size
    local panel_size = config.get('panel_size')
    vim.notify('Setting panel size to: ' .. panel_size, vim.log.levels.DEBUG)
    M.execute("resize-pane -t " .. vim.fn.shellescape(M.server_pane) .. " -x " .. vim.fn.shellescape(panel_size))

    -- Zoom current pane
    vim.notify('Zooming current pane', vim.log.levels.DEBUG)
    M.execute('resize-pane -Z')
  else
    vim.notify('MATLAB server pane already exists', vim.log.levels.DEBUG)
  end
end

-- Stop the MATLAB server
function M.stop_server()
  if not M.exists() or not M.server_pane then
    return
  end

  if M.get_server_pane() then
    M.run('quit')
    M.server_pane = nil
  end
end

return M