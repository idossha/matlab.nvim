-- MATLAB workspace management functionality
local M = {}
local tmux = require('matlab.tmux')

-- Display variables in the MATLAB workspace in the tmux pane
-- Note: Both toggle() and show() use 'whos' since 'workspace' command
-- requires MATLAB desktop which is not available in -nodesktop mode
function M.toggle()
  tmux.run('whos')
end

-- Display variables in the MATLAB workspace in the tmux pane
function M.show()
  tmux.run('whos')
end

-- Clear all variables in the workspace
function M.clear()
  tmux.run('clear all')
end

-- Save the workspace to a file
function M.save(filename)
  if not tmux.exists() then
    vim.notify('MATLAB server not running', vim.log.levels.ERROR)
    return
  end
  
  if filename then
    -- Validate filename
    if type(filename) ~= 'string' or filename == '' then
      vim.notify('Invalid filename provided', vim.log.levels.ERROR)
      return
    end
    -- Ensure .mat extension
    if not filename:match('%.mat$') then
      filename = filename .. '.mat'
    end
    tmux.run('save ' .. vim.fn.shellescape(filename))
    vim.notify('Workspace saved to: ' .. filename, vim.log.levels.INFO)
  else
    -- Generate default filename based on current date/time
    local default_file = 'workspace_' .. os.date('%Y%m%d_%H%M%S') .. '.mat'
    tmux.run('save ' .. vim.fn.shellescape(default_file))
    vim.notify('Workspace saved to: ' .. default_file, vim.log.levels.INFO)
  end
end

-- Load a workspace from a file
function M.load(filename)
  if not tmux.exists() then
    vim.notify('MATLAB server not running', vim.log.levels.ERROR)
    return
  end
  
  if filename then
    -- Validate filename
    if type(filename) ~= 'string' or filename == '' then
      vim.notify('Invalid filename provided', vim.log.levels.ERROR)
      return
    end
    -- Check if file exists
    if vim.fn.filereadable(filename) ~= 1 then
      vim.notify('File not found: ' .. filename, vim.log.levels.ERROR)
      return
    end
    tmux.run('load ' .. vim.fn.shellescape(filename))
    vim.notify('Workspace loaded from: ' .. filename, vim.log.levels.INFO)
  else
    -- Prompt user to select a MAT file
    local mat_files = vim.fn.glob('*.mat', false, true)
    if #mat_files == 0 then
      vim.notify('No .mat files found in current directory', vim.log.levels.WARN)
      return
    end
    
    vim.ui.select(mat_files, {
      prompt = 'Select a workspace file to load:',
    }, function(choice)
      if choice then
        tmux.run('load ' .. vim.fn.shellescape(choice))
        vim.notify('Workspace loaded from: ' .. choice, vim.log.levels.INFO)
      end
    end)
  end
end

return M