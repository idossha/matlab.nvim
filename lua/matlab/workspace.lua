-- MATLAB workspace management functionality
local M = {}
local tmux = require('matlab.tmux')

-- Display variables in the MATLAB workspace in the MATLAB window
function M.toggle()
  -- Show in MATLAB window using the Workspace browser
  tmux.run('workspace')
end

-- Display variables in the MATLAB workspace in the tmux pane
function M.show()
  -- Run whos in the tmux pane
  tmux.run('whos')
end

-- Clear all variables in the workspace
function M.clear()
  tmux.run('clear all')
end

-- Save the workspace to a file
function M.save(filename)
  if filename then
    tmux.run('save ' .. filename)
  else
    -- Generate default filename based on current date/time
    local default_file = 'workspace_' .. os.date('%Y%m%d_%H%M%S')
    tmux.run('save ' .. default_file)
  end
end

-- Load a workspace from a file
function M.load(filename)
  if filename then
    tmux.run('load ' .. filename)
  else
    -- Prompt user to select a MAT file
    vim.ui.select(vim.fn.glob('*.mat', false, true), {
      prompt = 'Select a workspace file to load:',
    }, function(choice)
      if choice then
        tmux.run('load ' .. choice)
      end
    end)
  end
end

return M