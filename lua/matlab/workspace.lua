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

  -- Simple approach: just run a custom command to get workspace variables silently
  local temp_file = os.tmpname()
  
  -- Create a custom command that doesn't show output in the tmux pane
  local command = string.format([[
matlab_nvim_show_workspace('%s');
  ]], temp_file)
  
  -- First check if our helper function exists, if not, create it
  local create_helper_cmd = [[
if ~exist('matlab_nvim_show_workspace', 'file')
    % Create our helper function if it doesn't exist
    matlab_nvim_show_workspace_str = sprintf(['function matlab_nvim_show_workspace(filename)\n',...
    '    %% Save workspace info to file without displaying in console\n',...
    '    f = fopen(filename, ''w'');\n',...
    '    fprintf(f, ''=== MATLAB Workspace Variables ===\\n\\n'');\n',...
    '    w = evalin(''base'', ''whos'');\n',...
    '    if isempty(w)\n',...
    '        fprintf(f, ''No variables in workspace.\\n'');\n',...
    '    else\n',...
    '        fprintf(f, ''  Name                Size             Bytes  Class        Attributes\\n'');\n',...
    '        fprintf(f, ''  ----------------------------------------------------------------------\\n'');\n',...
    '        for i = 1:length(w)\n',...
    '            v = w(i);\n',...
    '            %% Format size string\n',...
    '            sz = sprintf(''%%dx'', v.size);\n',...
    '            sz = sz(1:end-1);\n',...
    '            if isempty(sz), sz = ''0x0''; end\n',...
    '            %% Format attributes\n',...
    '            attr = '''';\n',...
    '            if v.global, attr = [attr ''global '']; end\n',...
    '            if v.complex, attr = [attr ''complex '']; end\n',...
    '            %% Write the line\n',...
    '            fprintf(f, ''  %%-19s %%-16s %%7d  %%-12s %%s\\n'', v.name, sz, v.bytes, v.class, attr);\n',...
    '        end\n',...
    '    end\n',...
    '    fclose(f);\n',...
    'end']);
    % Write the function to a temporary file and run it to create the function
    evalc(matlab_nvim_show_workspace_str);
end
  ]]
  
  -- First create the helper function if needed
  local target = tmux.get_server_pane()
  if target then
    -- Send helper function creation command
    local cmd = "send-keys -t " .. vim.fn.shellescape(target) .. " " .. vim.fn.shellescape(create_helper_cmd) .. " C-m"
    tmux.execute(cmd)
    
    -- Wait a bit
    vim.fn.system('sleep 0.3')
    
    -- Now call our helper function to generate the file
    cmd = "send-keys -t " .. vim.fn.shellescape(target) .. " " .. vim.fn.shellescape(command) .. " C-m"
    tmux.execute(cmd)
  else
    return {
      "=== MATLAB Workspace Variables ===",
      "",
      "Could not connect to MATLAB tmux pane.",
      "",
      "Press 'q' to close this window, 'r' to refresh"
    }
  end
  
  -- Wait for MATLAB to create the file
  vim.fn.system('sleep 0.5')
  
  -- Read the output file
  local output_lines = {}
  local file = io.open(temp_file, "r")
  
  if file then
    for line in file:lines() do
      table.insert(output_lines, line)
    end
    file:close()
    
    -- Remove the temporary file
    os.remove(temp_file)
    
    -- If we got content, return it with help text
    if #output_lines > 0 then
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