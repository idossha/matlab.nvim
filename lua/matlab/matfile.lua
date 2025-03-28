-- lua/matlab/matfile.lua
local M = {}
local tmux = require('matlab.tmux')
local config = require('matlab.config')

function M.view_mat_file(file_path)
  -- Create a new buffer for displaying .mat contents
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_name(buf, 'MAT-View: ' .. vim.fn.fnamemodify(file_path, ':t'))
  
  -- Set initial content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    'Loading MAT file: ' .. file_path,
    'Please wait, starting MATLAB...'
  })
  
  -- Open the buffer in a new window
  vim.cmd('vsplit')
  vim.api.nvim_win_set_buf(0, buf)
  
  -- Ensure MATLAB is running
  if not tmux.get_server_pane() then
    tmux.start_server(false)
  end
  
  -- Create a temporary script to analyze the .mat file
  local temp_script = os.tmpname() .. '.m'
  local f = io.open(temp_script, 'w')
  if not f then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      'Error: Failed to create temporary script',
      'Check permissions and disk space'
    })
    return
  end
  
  -- Escape special characters in the file path for MATLAB
  local escaped_path = file_path:gsub("\\", "\\\\"):gsub("'", "''")
  
  -- Write MATLAB script to inspect the .mat file
  f:write("try\n")
  f:write("  disp('===MAT_FILE_START===');\n")
  f:write("  matInfo = whos('-file', '" .. escaped_path .. "');\n")
  f:write("  disp(['MAT File: " .. escaped_path .. "']);\n")
  f:write("  disp(['Variables: ' num2str(length(matInfo))]);\n")
  f:write("  disp('====================');\n")
  f:write("  disp(' ');\n")
  f:write("  data = load('" .. escaped_path .. "');\n")
  f:write("  for i = 1:length(matInfo)\n")
  f:write("    var = matInfo(i);\n")
  f:write("    disp(['## ' var.name]);\n")
  f:write("    disp(['Type: ' var.class ', Size: ' mat2str(var.size) ', Bytes: ' num2str(var.bytes)]);\n")
  f:write("    try\n")
  f:write("      value = data.(var.name);\n")
  f:write("      if isnumeric(value) || islogical(value)\n")
  f:write("        if numel(value) <= 20\n")
  f:write("          disp(['Value: ' mat2str(value)]);\n")
  f:write("        else\n")
  f:write("          if ismatrix(value) && min(size(value)) > 1\n")
  f:write("            preview = value(1:min(3,size(value,1)), 1:min(3,size(value,2)));\n")
  f:write("            disp(['Preview (3x3): ' mat2str(preview)]);\n")
  f:write("          else\n")
  f:write("            preview = value(1:min(5,numel(value)));\n")
  f:write("            disp(['Preview (first 5): ' mat2str(preview)]);\n")
  f:write("          end\n")
  f:write("        end\n")
  f:write("      elseif ischar(value)\n")
  f:write("        if length(value) <= 100\n")
  f:write("          disp(['Value: \"' value '\"']);\n")
  f:write("        else\n")
  f:write("          disp(['Preview: \"' value(1:97) '...\"']);\n")
  f:write("        end\n")
  f:write("      elseif isstruct(value)\n")
  f:write("        fields = fieldnames(value);\n")
  f:write("        fieldStr = 'Structure with fields: ';\n")
  f:write("        for f = 1:length(fields)\n")
  f:write("          if f > 1, fieldStr = [fieldStr ', ']; end\n")
  f:write("          fieldStr = [fieldStr fields{f}];\n")
  f:write("        end\n")
  f:write("        disp(fieldStr);\n")
  f:write("      elseif iscell(value)\n")
  f:write("        disp(['Cell array with ' num2str(numel(value)) ' elements']);\n")
  f:write("      else\n")
  f:write("        disp(['Complex data type: ' class(value)]);\n")
  f:write("      end\n")
  f:write("    catch\n")
  f:write("      disp('Could not preview this variable');\n")
  f:write("    end\n")
  f:write("    disp(' ');\n")
  f:write("  end\n")
  f:write("  disp('===MAT_FILE_END===');\n")
  f:write("catch ex\n")
  f:write("  disp('===MAT_FILE_START===');\n")
  f:write("  disp(['Error: ' ex.message]);\n")
  f:write("  disp('===MAT_FILE_END===');\n")
  f:write("end\n")
  f:write("exit;\n")
  f:close()
  
  -- Run MATLAB script and capture output
  local executable = config.get('executable')
  local command = executable .. ' -nodisplay -nosplash -r "run(''' .. temp_script:gsub("'", "''") .. ''')"'
  
  -- Use jobstart to run MATLAB in the background
  local output_data = {}
  local in_data_section = false
  
  -- Start the job
  local job_id = vim.fn.jobstart(command, {
    on_stdout = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line == "===MAT_FILE_START===" then
            in_data_section = true
          elseif line == "===MAT_FILE_END===" then
            in_data_section = false
          elseif in_data_section then
            table.insert(output_data, line)
          end
        end
      end
    end,
    on_stderr = function(_, data)
      if data then
        for _, line in ipairs(data) do
          if line == "===MAT_FILE_START===" then
            in_data_section = true
          elseif line == "===MAT_FILE_END===" then
            in_data_section = false
          elseif in_data_section then
            table.insert(output_data, line)
          end
        end
      end
    end,
    on_exit = function()
      -- Update buffer with MATLAB output
      if #output_data == 0 then
        table.insert(output_data, "No output received from MATLAB")
        table.insert(output_data, "Check your MATLAB installation and configuration")
      end
      
      -- Add help text
      table.insert(output_data, "")
      table.insert(output_data, "Press q to close this view")
      
      -- Update the buffer
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, output_data)
      
      -- Set up keymaps
      vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':bdelete<CR>', 
                                 {noremap = true, silent = true})
      
      -- Clean up temp file
      os.remove(temp_script)
    end
  })
  
  if job_id <= 0 then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
      "Error: Failed to start MATLAB process",
      "Check your MATLAB configuration and executable path",
      "Current path: " .. executable
    })
  end
  
  return buf
end

return M
