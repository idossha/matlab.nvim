-- Commands for matlab.nvim
local M = {}
local tmux = require('matlab.tmux')

-- Check if the current buffer is a MATLAB script
function M.is_matlab_script()
  local filetype = vim.bo.filetype
  if filetype == 'matlab' or filetype == 'octave' then
    return true
  end
  vim.notify('Not a MATLAB script.', vim.log.levels.WARN)
  return false
end

-- Get the MATLAB filename (without extension)
function M.get_filename()
  return vim.fn.expand('%:t'):gsub('%.m', '')
end

-- Run a MATLAB script
function M.run(command)
  if not tmux.exists() then
    return
  end

  if command then
    tmux.run(command)
  else
    -- Make sure that this is actually a MATLAB script
    if not M.is_matlab_script() then
      return
    end
    
    -- Check if buffer is modifiable and can be written
    if not vim.bo.modifiable then
      vim.notify('Buffer is not modifiable', vim.log.levels.ERROR)
      return
    end
    
    -- Only write if buffer is modified or if file doesn't exist
    if vim.bo.modified or vim.fn.filereadable(vim.fn.expand('%')) ~= 1 then
      local ok, err = pcall(vim.cmd, 'write')
      if not ok then
        vim.notify('Failed to save file: ' .. tostring(err), vim.log.levels.ERROR)
        return
      end
    end
    
    tmux.run(M.get_filename())
  end
end

-- Open current script in MATLAB GUI
function M.open_in_gui()
  if not M.is_matlab_script() then
    return
  end
  
  -- Save file before opening in GUI
  if vim.bo.modified then
    local ok, err = pcall(vim.cmd, 'write')
    if not ok then
      vim.notify('Failed to save file: ' .. tostring(err), vim.log.levels.ERROR)
      return
    end
  end
  
  local filepath = vim.fn.expand('%:p')
  if filepath == '' or vim.fn.filereadable(filepath) ~= 1 then
    vim.notify('File does not exist or is not readable', vim.log.levels.ERROR)
    return
  end
  
  local executable = require('matlab.config').get('executable')
  
  -- Build a system command to open the file directly in MATLAB
  local cmd
  if vim.fn.has('mac') == 1 then
    cmd = executable .. ' -r "edit ' .. filepath .. '"'
  elseif vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
    cmd = executable .. ' /r "edit ' .. filepath .. '"'
  else -- Linux/WSL
    -- Note: This opens in GUI mode (doesn't use -nodesktop flag)
    -- DISPLAY will be inherited from the parent environment, not from the tmux pane
    cmd = executable .. ' -r "edit ' .. filepath .. '"'
  end
  
  -- Execute the command in the background
  -- This spawns a new MATLAB process separate from the tmux CLI instance
  vim.fn.jobstart(cmd)
end

-- Show documentation for the word under cursor
function M.doc()
  if not tmux.exists() then
    return
  end

  return tmux.run('help ' .. vim.fn.expand('<cword>'), true, true)
end

return M