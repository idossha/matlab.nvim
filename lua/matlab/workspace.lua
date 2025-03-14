-- MATLAB workspace management functionality
local M = {}
local tmux = require('matlab.tmux')

-- Track workspace window buffer and window IDs
M.workspace_buf = nil
M.workspace_win = nil

-- Helper function to create a floating window on the side
local function create_floating_window()
  -- Calculate window size based on editor dimensions
  -- Use 30% of the screen width for the sidebar
  local width = math.floor(vim.o.columns * 0.3)
  local height = vim.o.lines - 4  -- Leave some space for statusline
  
  -- Position at the right side of the screen
  local col = vim.o.columns - width
  local row = 1  -- Start just below the tabline/statusline

  -- Create a buffer if it doesn't exist
  if not M.workspace_buf or not vim.api.nvim_buf_is_valid(M.workspace_buf) then
    M.workspace_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(M.workspace_buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(M.workspace_buf, 'filetype', 'matlab-workspace')
  end

  -- Window options
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'rounded',
    title = ' MATLAB Workspace ',
    title_pos = 'left',
  }

  -- Create the window
  M.workspace_win = vim.api.nvim_open_win(M.workspace_buf, true, opts)
  
  -- Set some window-local options
  vim.api.nvim_win_set_option(M.workspace_win, 'wrap', false)
  vim.api.nvim_win_set_option(M.workspace_win, 'cursorline', true)
  
  -- Set keymaps
  local keymaps = {
    ['q'] = ':lua require("matlab.workspace").close()<CR>',
    ['<ESC>'] = ':lua require("matlab.workspace").close()<CR>',
    ['r'] = ':lua require("matlab.workspace").refresh()<CR>',
  }
  
  for k, v in pairs(keymaps) do
    vim.api.nvim_buf_set_keymap(M.workspace_buf, 'n', k, v, { noremap = true, silent = true })
  end
  
  return M.workspace_win
end

-- Function to fetch workspace variables from MATLAB
local function fetch_workspace_variables()
  if not tmux.get_server_pane() then
    return {
      "=== MATLAB Not Running ===",
      "",
      "No MATLAB session is currently running.",
      "Start MATLAB with :MatlabStartServer first.",
      "",
      "Press 'q' to close this window."
    }
  end

  -- Create a temporary file to store MATLAB output
  local temp_file = os.tmpname()
  
  -- Use disp and diary to capture the output of whos
  -- Use 'evalc' to suppress output to the MATLAB console
  -- Pass true for skip_interrupt and skip_output
  tmux.run('diary(\'' .. temp_file .. '\'); evalc(\'disp(\\\'=== MATLAB Workspace Variables ===\\\'); whos\'); diary off;', true, true)
  
  -- Wait a bit for MATLAB to execute and write the file
  vim.fn.system('sleep 0.5')
  
  -- Try to read the output file
  local output_lines = {}
  local file = io.open(temp_file, "r")
  
  if file then
    -- Read all lines from the file
    for line in file:lines() do
      table.insert(output_lines, line)
    end
    file:close()
    
    -- Remove the temporary file
    os.remove(temp_file)
    
    -- If we got content, return it
    if #output_lines > 0 then
      -- Add help text at the end
      table.insert(output_lines, "")
      table.insert(output_lines, "Press 'q' to close this window, 'r' to refresh")
      return output_lines
    end
  end
  
  -- Fallback message if we couldn't get the output
  return {
    "=== MATLAB Workspace Variables ===",
    "",
    "Could not retrieve workspace variables.",
    "The MATLAB session might be busy or unresponsive.",
    "",
    "Press 'q' to close this window, 'r' to refresh"
  }
end

-- Display variables in the MATLAB workspace
function M.show()
  tmux.run('whos')
end

-- Close the workspace window
function M.close()
  if M.workspace_win and vim.api.nvim_win_is_valid(M.workspace_win) then
    vim.api.nvim_win_close(M.workspace_win, true)
    M.workspace_win = nil
  end
end

-- Refresh workspace window content
function M.refresh()
  if not M.workspace_buf or not vim.api.nvim_buf_is_valid(M.workspace_buf) then
    return
  end
  
  -- Display loading message
  vim.api.nvim_buf_set_lines(M.workspace_buf, 0, -1, false, {"Refreshing MATLAB workspace variables..."})
  
  -- Fetch and display updated workspace variables
  vim.defer_fn(function()
    local content = fetch_workspace_variables()
    if M.workspace_buf and vim.api.nvim_buf_is_valid(M.workspace_buf) then
      vim.api.nvim_buf_set_lines(M.workspace_buf, 0, -1, false, content)
    end
  end, 600) -- Increased delay to ensure MATLAB has time to execute
end

-- Toggle visibility of the MATLAB workspace window
function M.toggle()
  if not tmux.get_server_pane() then
    -- No MATLAB server running, start one
    tmux.start_server(false)
    
    -- Wait a bit for MATLAB to start
    vim.defer_fn(function()
      M.toggle()
    end, 1000)
    return
  end
  
  -- If window exists and is valid, close it
  if M.workspace_win and vim.api.nvim_win_is_valid(M.workspace_win) then
    M.close()
    return
  end
  
  -- Create a new window and populate it with workspace data
  create_floating_window()
  
  -- Display loading message
  vim.api.nvim_buf_set_lines(M.workspace_buf, 0, -1, false, {"Loading MATLAB workspace variables..."})
  
  -- Fetch and display workspace variables in the floating window
  vim.defer_fn(function()
    local content = fetch_workspace_variables()
    if M.workspace_buf and vim.api.nvim_buf_is_valid(M.workspace_buf) then
      vim.api.nvim_buf_set_lines(M.workspace_buf, 0, -1, false, content)
    end
  end, 600) -- Increased delay to ensure MATLAB has time to execute
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