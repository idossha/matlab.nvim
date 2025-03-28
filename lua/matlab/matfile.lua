-- lua/matlab/matfile.lua
local M = {}
local tmux = require('matlab.tmux')
local config = require('matlab.config')

-- View MAT file contents
function M.view_mat_file(file_path)
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_name(buf, 'MAT-View: ' .. vim.fn.fnamemodify(file_path, ':t'))
  
  -- Set initial content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    'Loading MAT file: ' .. file_path,
    'Please wait...'
  })
  
  -- Show the buffer
  vim.cmd('vsplit')
  vim.api.nvim_win_set_buf(0, buf)
  
  -- Ensure MATLAB is available
  if not tmux.get_server_pane() then
    tmux.start_server(false)
  end
  
  -- Wait for MATLAB to be ready
  vim.defer_fn(function()
    -- Execute MATLAB command to inspect the MAT file
    local cmd = "disp('MAT File Contents:'); who('-file', '" .. 
                file_path:gsub("'", "''") .. "'); disp(' '); " ..
                "vars = who('-file', '" .. file_path:gsub("'", "''") .. "'); " ..
                "for i=1:length(vars), " ..
                "  disp(['## ' vars{i}]); " ..
                "  data = load('" .. file_path:gsub("'", "''") .. "', vars{i}); " ..
                "  val = data.(vars{i}); " ..
                "  disp(['Type: ' class(val) ', Size: ' mat2str(size(val))]); " ..
                "  disp(' '); " ..
                "end"
    
    -- Send command to MATLAB
    tmux.run(cmd, true, true)
    
    -- Get MATLAB output
    local output = vim.fn.systemlist("tmux capture-pane -p -t " .. tmux.get_server_pane())
    
    -- Process output to extract just the MAT file info
    local processed_output = {}
    local capture_mode = false
    
    for _, line in ipairs(output) do
      if line:match("MAT File Contents:") then
        capture_mode = true
        table.insert(processed_output, line)
      elseif capture_mode then
        table.insert(processed_output, line)
      end
    end
    
    -- Add usage instructions
    table.insert(processed_output, "")
    table.insert(processed_output, "Press q to close this view")
    
    -- Update buffer with the information
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, processed_output)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    
    -- Set keymaps
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':bdelete<CR>', {noremap = true, silent = true})
  end, 1000)  -- Wait 1 second for MATLAB to be ready
  
  return buf
end

return M
