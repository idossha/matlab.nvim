-- MATLAB workspace management functionality
local M = {}
local tmux = require('matlab.tmux')

-- Track workspace window visibility state
M.workspace_visible = false

-- Display variables in the MATLAB workspace
function M.show()
  tmux.run('whos')
  tmux.open_pane()
  M.workspace_visible = true
end

-- Toggle visibility of the MATLAB workspace window
function M.toggle()
  if not tmux.get_server_pane() then
    -- No MATLAB server running, start one
    tmux.start_server(false)
    M.workspace_visible = true
    return
  end
  
  if M.workspace_visible then
    -- Workspace is currently visible, switch back to Neovim
    -- Zoom the current pane to hide the MATLAB pane
    tmux.execute('resize-pane -Z')
    M.workspace_visible = false
  else
    -- Workspace is hidden, show it and run whos
    tmux.run('whos')
    tmux.open_pane()
    M.workspace_visible = true
  end
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