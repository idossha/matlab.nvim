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

-- Start the MATLAB server
function M.start_server(auto_start, startup_command)
  if not M.exists() then
    return
  end

  -- Check if autostart is enabled
  if auto_start and not config.get('auto_start') then
    return
  end

  if not M.get_server_pane() then
    -- Create new pane, start matlab in it and save its id
    local startup_cmd = 'cd ' .. vim.fn.shellescape(M.get_project_root()) .. ';'
    
    -- Add command to startup if provided
    if startup_command then
      startup_cmd = startup_cmd .. startup_command .. ';'
    end

    local mlcmd = 'clear && ' .. config.get('executable') .. ' -nodesktop -nosplash -r ' .. vim.fn.shellescape(startup_cmd)
    local cmd = 'split-window -dhPF "#{session_id}:#{window_id}.#{pane_id}" ' .. vim.fn.shellescape(mlcmd)
    M.server_pane = M.execute(cmd):gsub('[^%%$@%.:0-9]', '')

    if M.pane_exists() then
      vim.notify('MATLAB server started.', vim.log.levels.INFO)
    else
      vim.notify('Something went wrong starting the MATLAB server.', vim.log.levels.ERROR)
      return
    end

    -- Set pane size
    M.execute("resize-pane -t " .. vim.fn.shellescape(M.server_pane) .. " -x " .. vim.fn.shellescape(config.get('panel_size')))

    -- Zoom current pane
    M.execute('resize-pane -Z')
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