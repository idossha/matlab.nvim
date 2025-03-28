-- lua/matlab/matfile.lua
local M = {}
local tmux = require('matlab.tmux')
local config = require('matlab.config')

-- Function to handle .mat file opening
function M.handle_mat_file()
  local file_path = vim.fn.expand('%:p')
  
  -- Clear current buffer content
  vim.api.nvim_buf_set_option(0, 'modifiable', true)
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "Loading MATLAB .mat file...",
    "Please wait, starting MATLAB to analyze the file contents..."
  })
  vim.api.nvim_buf_set_option(0, 'modifiable', false)
  
  -- Start a background job to analyze the .mat file
  vim.schedule(function()
    -- Ensure MATLAB is running
    if not tmux.get_server_pane() then
      tmux.start_server(false)
    end
    
    -- Wait briefly for MATLAB to initialize
    vim.defer_fn(function()
      M.analyze_mat_file(file_path)
    end, 1000)
  end)
end

-- Function to analyze the .mat file using MATLAB
function M.analyze_mat_file(file_path)
  -- Get the MATLAB command prefix based on OS
  local matlab_exec = config.get('executable')
  
  -- Create MATLAB script to analyze the .mat file
  local script_content = string.format([[
  try
    fprintf(2, '===MAT_FILE_BEGIN===\n');
    matObj = matfile('%s');
    varInfo = whos(matObj);
    
    % Print file header
    fprintf(2, 'MAT File: %s\n');
    fprintf(2, 'Variables: %d\n', length(varInfo));
    fprintf(2, '====================\n\n');
    
    % Print variable information
    for i = 1:length(varInfo)
      var = varInfo(i);
      fprintf(2, '## %s\n', var.name);
      fprintf(2, 'Type: %s, Size: %s, Bytes: %d\n', var.class, mat2str(var.size), var.bytes);
      
      % Try to preview variable based on type
      try
        % Load the variable
        varData = matObj.(var.name);
        
        % Handle different variable types
        if isnumeric(varData) || islogical(varData)
          % Show numeric preview
          if numel(varData) <= 25
            % Small array - show all
            fprintf(2, 'Value:\n%s\n', mat2str(varData));
          else
            % Large array - show a small preview
            if ismatrix(varData) && min(size(varData)) > 1
              % 2D+ array - show 3x3 corner
              previewSize = min([3, size(varData, 1), size(varData, 2)]);
              previewData = varData(1:previewSize, 1:previewSize);
              fprintf(2, 'Preview (%dx%d of %s):\n%s\n', ...
                previewSize, previewSize, mat2str(size(varData)), mat2str(previewData));
            else
              % Vector - show first few elements
              previewData = varData(1:min(5, numel(varData)));
              fprintf(2, 'Preview (first %d of %d):\n%s\n', ...
                min(5, numel(varData)), numel(varData), mat2str(previewData));
            end
          end
        elseif ischar(varData)
          % Text preview
          if numel(varData) <= 100
            fprintf(2, 'Value: "%s"\n', varData);
          else
            fprintf(2, 'Preview: "%s..."\n', varData(1:97));
          end
        elseif isstruct(varData)
          % Structure preview
          fields = fieldnames(varData);
          fprintf(2, 'Structure with fields: ');
          for j = 1:length(fields)
            if j > 1, fprintf(2, ', '); end
            fprintf(2, '%s', fields{j});
          end
          fprintf(2, '\n');
          
          % If small struct array, show more details
          if numel(varData) <= 3
            for j = 1:numel(varData)
              fprintf(2, '  Element %d:\n', j);
              for k = 1:length(fields)
                fieldValue = varData(j).(fields{k});
                fprintf(2, '    %s: ', fields{k});
                if isnumeric(fieldValue) && numel(fieldValue) <= 10
                  fprintf(2, '%s', mat2str(fieldValue));
                elseif ischar(fieldValue) && numel(fieldValue) <= 30
                  fprintf(2, '"%s"', fieldValue);
                else
                  fprintf(2, '<%s>', class(fieldValue));
                end
                fprintf(2, '\n');
              end
            end
          end
        elseif iscell(varData)
          % Cell array preview
          fprintf(2, 'Cell array with %d elements\n', numel(varData));
          if numel(varData) <= 5
            for j = 1:numel(varData)
              fprintf(2, '  Cell %d: ', j);
              cellContent = varData{j};
              if isnumeric(cellContent) && numel(cellContent) <= 10
                fprintf(2, '%s', mat2str(cellContent));
              elseif ischar(cellContent) && numel(cellContent) <= 30
                fprintf(2, '"%s"', cellContent);
              else
                fprintf(2, '<%s>', class(cellContent));
              end
              fprintf(2, '\n');
            end
          end
        else
          fprintf(2, 'Complex data type, preview not available\n');
        end
      catch previewError
        fprintf(2, 'Could not preview: %s\n', previewError.message);
      end
      
      fprintf(2, '\n');
    end
    fprintf(2, '===MAT_FILE_END===\n');
  catch ex
    fprintf(2, '===MAT_FILE_BEGIN===\n');
    fprintf(2, 'Error loading MAT file: %s\n', ex.message);
    fprintf(2, '===MAT_FILE_END===\n');
  end
  exit;
  ]], file_path:gsub("\\", "\\\\"):gsub("'", "''"), file_path)
  
  -- Create a temporary script
  local temp_dir = vim.fn.tempname()
  vim.fn.mkdir(temp_dir, "p")
  local script_path = temp_dir .. '/mat_analyze.m'
  
  local f = io.open(script_path, 'w')
  if not f then
    vim.notify('Failed to create temporary script', vim.log.levels.ERROR)
    return
  end
  f:write(script_content)
  f:close()
  
  -- Build the MATLAB command
  local cmd
  if vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
    cmd = matlab_exec .. ' -nodisplay -nosplash -nodesktop /r "run(''' .. script_path:gsub("'", "''") .. ''')"'
  else
    cmd = matlab_exec .. ' -nodisplay -nosplash -nodesktop -r "run(''' .. script_path:gsub("'", "''") .. ''')"'
  end
  
  -- Run MATLAB as job and capture output
  local output_lines = {}
  local job_id = vim.fn.jobstart(cmd, {
    on_stderr = function(_, data)
      if data then
        -- Process MATLAB output
        local capture = false
        for _, line in ipairs(data) do
          if line == "===MAT_FILE_BEGIN===" then
            capture = true
          elseif line == "===MAT_FILE_END===" then
            capture = false
          elseif capture then
            table.insert(output_lines, line)
          end
        end
      end
    end,
    on_exit = function()
      -- Update buffer with MATLAB output
      vim.schedule(function()
        if #output_lines == 0 then
          output_lines = {"Error: No output from MATLAB", 
                          "Check that MATLAB is properly installed and configured"}
        end
        
        -- Add help text at the end
        table.insert(output_lines, "")
        table.insert(output_lines, "Press q to close this view")
        
        vim.api.nvim_buf_set_option(0, 'modifiable', true)
        vim.api.nvim_buf_set_lines(0, 0, -1, false, output_lines)
        vim.api.nvim_buf_set_option(0, 'modifiable', false)
        
        -- Set up syntax highlighting
        vim.cmd('set syntax=matlab_mat_view')
        
        -- Set up keymaps for the buffer
        vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':bdelete<CR>', {noremap = true, silent = true})
        
        -- Clean up temp files
        os.remove(script_path)
        os.rmdir(temp_dir)
      end)
    end
  })
  
  if job_id <= 0 then
    vim.notify('Failed to start MATLAB job', vim.log.levels.ERROR)
    vim.api.nvim_buf_set_option(0, 'modifiable', true)
    vim.api.nvim_buf_set_lines(0, 0, -1, false, {
      "Error: Failed to start MATLAB",
      "Check your MATLAB configuration in matlab.nvim settings"
    })
    vim.api.nvim_buf_set_option(0, 'modifiable', false)
  end
end

return M
