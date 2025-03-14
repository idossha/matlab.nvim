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

  -- Create two temporary files: one for capturing output and one for the script
  local temp_output_file = os.tmpname()
  local temp_script_file = os.tmpname() .. ".m"
  
  -- Create a simple MATLAB script file that will save workspace info to our temp file
  local file = io.open(temp_script_file, "w")
  if not file then
    return {
      "=== MATLAB Workspace Variables ===",
      "",
      "Could not create temporary script file.",
      "Check file permissions.",
      "",
      "Press 'q' to close this window, 'r' to refresh"
    }
  end
  
  -- Write a simple script to get workspace vars and output to file
  file:write(string.format([[
% Silent workspace capture script
fid = fopen('%s', 'w');
fprintf(fid, '=== MATLAB Workspace Variables ===\n\n');
vars = whos;
if isempty(vars)
    fprintf(fid, 'No variables in workspace.\n');
else
    % Print header
    fprintf(fid, '  Name                            Size                    Bytes  Class     Attributes\n');
    fprintf(fid, '  ------------------------------------------------------------------------------\n');
    
    % Print each variable
    for i = 1:length(vars)
        v = vars(i);
        % Format the size as a string
        if isempty(v.size)
            sizestr = '0x0';
        else
            sizestr = [num2str(v.size(1)) 'x' num2str(v.size(2))];
            if length(v.size) > 2
                % Handle N-dimensional arrays
                for d = 3:length(v.size)
                    sizestr = [sizestr 'x' num2str(v.size(d))];
                end
            end
        end
        
        % Format attributes
        attrs = '';
        if v.global
            attrs = [attrs 'global '];
        end
        if ~isempty(v.persistent) && v.persistent
            attrs = [attrs 'persistent '];
        end
        if v.complex
            attrs = [attrs 'complex '];
        end
        
        % Print the variable info
        fprintf(fid, '  %-30s %-20s %10d  %-8s  %s\n', v.name, sizestr, v.bytes, v.class, attrs);
    end
end
fclose(fid);
  ]], temp_output_file))
  file:close()
  
  -- Run the script silently without displaying output in the MATLAB window
  local matlab_cmd = string.format("run('%s'); delete('%s');", temp_script_file, temp_script_file)
  
  -- Execute the script using tmux directly
  local target = tmux.get_server_pane()
  if target then
    -- Use semicolon to suppress MATLAB output and send carriage return
    local cmd = "send-keys -t " .. vim.fn.shellescape(target) .. " " .. vim.fn.shellescape(matlab_cmd) .. " C-m"
    tmux.execute(cmd)
  else
    os.remove(temp_script_file)
    return {
      "=== MATLAB Workspace Variables ===",
      "",
      "Could not connect to MATLAB tmux pane.",
      "",
      "Press 'q' to close this window, 'r' to refresh"
    }
  end
  
  -- Wait for MATLAB to execute the script and write the output file
  vim.fn.system('sleep 1.0')
  
  -- Read the output file
  local output_lines = {}
  local file = io.open(temp_output_file, "r")
  
  if file then
    for line in file:lines() do
      table.insert(output_lines, line)
    end
    file:close()
    
    -- Remove the temporary output file
    os.remove(temp_output_file)
    
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