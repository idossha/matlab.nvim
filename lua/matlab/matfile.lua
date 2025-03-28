-- lua/matlab/matfile.lua
local M = {}
local tmux = require('matlab.tmux')
local config = require('matlab.config')

-- Create a buffer to display .mat file contents
function M.create_mat_buffer(mat_file_path)
  -- Create a split window for displaying the .mat contents
  vim.cmd('vsplit')
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, bufnr)
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(bufnr, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
  vim.api.nvim_buf_set_option(bufnr, 'filetype', 'matlab_mat_view')
  vim.api.nvim_buf_set_name(bufnr, 'MAT: ' .. vim.fn.fnamemodify(mat_file_path, ':t'))
  
  return bufnr
end

-- Load and display the contents of a .mat file
function M.load_mat_file(file_path)
  -- Ensure MATLAB is running
  if not tmux.pane_exists() then
    tmux.start_server(false)
  end
  
  -- Create a temporary script to load and inspect the .mat file
  local temp_script = os.tmpname() .. '.m'
  local f = io.open(temp_script, 'w')
  if not f then
    vim.notify('Failed to create temporary script', vim.log.levels.ERROR)
    return
  end
  
  -- Write MATLAB code to load and analyze the .mat file
  f:write(string.format([[
  try
    data = load('%s');
    fields = fieldnames(data);
    
    % Open a file for output
    fid = fopen('%s.out', 'w');
    
    % Write header
    fprintf(fid, 'MAT File: %s\n');
    fprintf(fid, '===================\n\n');
    
    % Iterate through fields
    for i = 1:length(fields)
      fieldName = fields{i};
      fieldValue = data.(fieldName);
      
      % Write field info
      fprintf(fid, '## %s\n', fieldName);
      
      % Get size and class
      sizeStr = mat2str(size(fieldValue));
      classStr = class(fieldValue);
      fprintf(fid, 'Type: %s, Size: %s\n', classStr, sizeStr);
      
      % Show preview based on data type
      if isnumeric(fieldValue) || islogical(fieldValue)
        if numel(fieldValue) <= 25
          % Show all values for small arrays
          fprintf(fid, 'Value:\n%s\n', mat2str(fieldValue));
        else
          % Show first few values for large arrays
          if ismatrix(fieldValue) && min(size(fieldValue)) > 1
            % 2D+ array - show 3x3 preview
            preview = fieldValue(1:min(3,size(fieldValue,1)), 1:min(3,size(fieldValue,2)));
            fprintf(fid, 'Preview (3x3):\n%s\n', mat2str(preview));
          else
            % 1D array - show first 5
            preview = fieldValue(1:min(5,numel(fieldValue)));
            fprintf(fid, 'Preview (first 5):\n%s\n', mat2str(preview));
          end
        end
      elseif ischar(fieldValue)
        if numel(fieldValue) <= 200
          fprintf(fid, 'Value: "%s"\n', fieldValue);
        else
          fprintf(fid, 'Preview: "%s..."\n', fieldValue(1:197));
        end
      elseif isstruct(fieldValue)
        sFields = fieldnames(fieldValue);
        fprintf(fid, 'Structure with fields: ');
        for j = 1:length(sFields)
          if j > 1, fprintf(fid, ', '); end
          fprintf(fid, '%s', sFields{j});
        end
        fprintf(fid, '\n');
      elseif iscell(fieldValue)
        fprintf(fid, 'Cell array\n');
        if numel(fieldValue) <= 5
          for j = 1:numel(fieldValue)
            cellContent = fieldValue{j};
            fprintf(fid, '  Cell %d: ', j);
            if isnumeric(cellContent)
              fprintf(fid, '[%s]', mat2str(cellContent));
            elseif ischar(cellContent)
              fprintf(fid, '"%s"', cellContent);
            else
              fprintf(fid, '<%s>', class(cellContent));
            end
            fprintf(fid, '\n');
          end
        else
          fprintf(fid, 'Preview: %d cells\n', numel(fieldValue));
        end
      else
        fprintf(fid, 'Complex data type\n');
      end
      
      fprintf(fid, '\n');
    end
    
    fclose(fid);
    exit;
  catch ex
    fid = fopen('%s.out', 'w');
    fprintf(fid, 'Error loading MAT file: %s\n', ex.message);
    fclose(fid);
    exit;
  end
  ]], 
  vim.fn.shellescape(file_path):gsub("'", "''"), -- Escape file path for MATLAB string
  temp_script,
  file_path,
  temp_script))
  f:close()
  
  -- Run the script in MATLAB
  local matlab_cmd = M.build_matlab_command(config.get('executable'), 'run ' .. vim.fn.shellescape(temp_script))
  os.execute(matlab_cmd)
  
  -- Read the output
  local output_file = temp_script .. '.out'
  local output_content = {}
  local output = io.open(output_file, 'r')
  if output then
    for line in output:lines() do
      table.insert(output_content, line)
    end
    output:close()
  else
    vim.notify('Failed to read MATLAB output', vim.log.levels.ERROR)
    return
  end
  
  -- Display the output
  local bufnr = M.create_mat_buffer(file_path)
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, output_content)
  vim.api.nvim_buf_set_option(bufnr, 'modifiable', false)
  
  -- Clean up temporary files
  os.remove(temp_script)
  os.remove(output_file)
  
  -- Set up keymaps for the buffer
  vim.api.nvim_buf_set_keymap(bufnr, 'n', 'q', ':bdelete<CR>', {noremap = true, silent = true})
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<CR>', ':lua require("matlab.matfile").inspect_variable()<CR>', {noremap = true})
  
  return bufnr
end

-- Helper function to build platform-specific MATLAB command
function M.build_matlab_command(executable, command)
  -- Different platforms have different command formats
  if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
    return executable .. ' -nodesktop -nosplash /r ' .. command
  else
    return executable .. ' -nodesktop -nosplash -r ' .. command
  end
end

-- Load the current .mat file
function M.load_current_file()
  local file_path = vim.fn.expand('%:p')
  if vim.fn.filereadable(file_path) == 1 then
    M.load_mat_file(file_path)
  else
    vim.notify('Cannot read file: ' .. file_path, vim.log.levels.ERROR)
  end
end

-- Inspect a specific variable (when user presses Enter on a variable)
function M.inspect_variable()
  local line = vim.fn.getline('.')
  
  -- Check if this looks like a variable line (starts with ##)
  if line:match('^## (.+)$') then
    local var_name = line:match('^## (.+)$')
    vim.notify('Inspecting variable: ' .. var_name, vim.log.levels.INFO)
    
    -- Get the .mat file path from buffer name
    local buf_name = vim.fn.bufname('%')
    local mat_file = buf_name:match('MAT: (.+)$')
    
    -- TODO: Implement detailed inspection of a single variable
    -- For now, just highlight the section
    
    -- Find the section boundaries
    local current_line = vim.fn.line('.')
    local start_line = current_line
    local end_line = current_line
    
    -- Search forward for the next section or EOF
    local buf_lines = vim.api.nvim_buf_get_lines(0, current_line, -1, false)
    for i, next_line in ipairs(buf_lines) do
      if i > 1 and next_line:match('^## ') then
        end_line = current_line + i - 2
        break
      end
      if i == #buf_lines then
        end_line = current_line + i - 1
      end
    end
    
    -- Highlight the section
    local ns_id = vim.api.nvim_create_namespace('matlab_mat_inspect')
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    for i = start_line, end_line do
      vim.api.nvim_buf_add_highlight(0, ns_id, 'Search', i-1, 0, -1)
    end
    
    -- Set up a timer to clear the highlight after a few seconds
    vim.defer_fn(function()
      vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    end, 3000)
  end
end

return M
