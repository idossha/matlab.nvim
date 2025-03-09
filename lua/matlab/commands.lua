-- MATLAB commands module for executing MATLAB code
local M = {}

-- Dependencies
local has_plenary, Job = pcall(require, 'plenary.job')

if not has_plenary then
  vim.notify("MATLAB.nvim: plenary.nvim is required for executing MATLAB code", vim.log.levels.ERROR)
end

-- Store configuration
local config = {}

-- Setup the module
function M.setup(opts)
  config = opts
end

-- Execute code in MATLAB
function M.execute_code(code, callback)
  if not has_plenary then
    vim.notify("Cannot execute MATLAB code: plenary.nvim not found", vim.log.levels.ERROR)
    return
  end
  
  -- Check if MATLAB executable exists
  local has_executable = vim.fn.executable(config.matlab_executable) == 1
  
  if not has_executable then
    vim.notify(
      string.format(
        "MATLAB executable '%s' not found. Please check your configuration:\n" ..
        "1. Make sure MATLAB is installed\n" ..
        "2. Update your config with: require('matlab').setup({ matlab_executable = '/path/to/matlab' })\n" ..
        "3. Or add MATLAB to your system PATH",
        config.matlab_executable
      ),
      vim.log.levels.ERROR
    )
    return
  end

  -- Create a temporary file for the code
  local code_file = vim.fn.tempname() .. '.m'
  local f = io.open(code_file, 'w')
  if not f then
    vim.notify("Failed to create temporary file for MATLAB code", vim.log.levels.ERROR)
    return
  end
  f:write(code)
  f:close()
  
  -- Create a temporary file for the output
  local output_file = vim.fn.tempname() .. '.txt'
  
  -- Create a MATLAB script to run the code and capture output
  local script_file = vim.fn.tempname() .. '.m'
  local script = [[
    % Redirect output to file
    diary(']] .. output_file .. [[');
    
    % Display startup message to confirm MATLAB is running
    disp('MATLAB_NVIM_STARTED');
    
    % Execute the code
    try
      run(']] .. code_file .. [[');
      disp('MATLAB_NVIM_SUCCESS');
    catch e
      disp('MATLAB_NVIM_ERROR');
      disp(e.message);
    end
    
    % Explicitly write to the output file to ensure it exists
    fid = fopen(']] .. output_file .. [[', 'a');
    if fid > 0
        fprintf(fid, 'MATLAB execution completed\n');
        fclose(fid);
    end
    
    % Close the diary
    diary off;
    
    % Exit MATLAB
    exit;
  ]]
  
  local f = io.open(script_file, 'w')
  if not f then
    vim.notify("Failed to create temporary script file", vim.log.levels.ERROR)
    return
  end
  f:write(script)
  f:close()
  
  -- Print debug info to help diagnose issues
  vim.notify("Executing MATLAB with: " .. config.matlab_executable, vim.log.levels.INFO)
  vim.notify("Script file: " .. script_file, vim.log.levels.DEBUG)
  
  -- Create a floating window to show progress
  local progress_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(progress_buf, 0, -1, false, {"Executing MATLAB code...", "", "Command: " .. config.matlab_executable, "Press 'q' to cancel"})
  
  local width = 60
  local height = 6
  local ui = vim.api.nvim_list_uis()[1]
  
  local progress_win = vim.api.nvim_open_win(progress_buf, false, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor((ui.height - height) / 2),
    col = math.floor((ui.width - width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = 'MATLAB',
    title_pos = 'center',
  })
  
  -- Add keymap to cancel execution
  vim.api.nvim_buf_set_keymap(progress_buf, 'n', 'q', '', {
    callback = function()
      if job then
        job:shutdown()
      end
      if vim.api.nvim_win_is_valid(progress_win) then
        vim.api.nvim_win_close(progress_win, true)
      end
      if vim.api.nvim_buf_is_valid(progress_buf) then
        vim.api.nvim_buf_delete(progress_buf, { force = true })
      end
      vim.notify("MATLAB execution cancelled", vim.log.levels.INFO)
    end,
    noremap = true,
    silent = true,
  })
  
  -- Set a timer to update the progress window
  local start_time = vim.loop.now()
  local timer = vim.loop.new_timer()
  local dots = 0
  
  timer:start(500, 500, function()
    vim.schedule(function()
      if not vim.api.nvim_win_is_valid(progress_win) then
        timer:stop()
        return
      end
      
      dots = (dots + 1) % 4
      local dot_str = string.rep(".", dots)
      local elapsed = math.floor((vim.loop.now() - start_time) / 1000)
      
      vim.api.nvim_buf_set_lines(progress_buf, 0, 1, false, {"Executing MATLAB code" .. dot_str})
      vim.api.nvim_buf_set_lines(progress_buf, 1, 2, false, {"Time elapsed: " .. elapsed .. "s"})
    end)
  end)
  
  -- Set timeout for MATLAB execution (30 seconds)
  local timeout = vim.loop.new_timer()
  timeout:start(30000, 0, function()
    vim.schedule(function()
      if job then
        vim.notify("MATLAB execution timeout after 30 seconds. You may need to manually kill the MATLAB process.", vim.log.levels.ERROR)
        job:shutdown()
        
        if vim.api.nvim_win_is_valid(progress_win) then
          vim.api.nvim_win_close(progress_win, true)
        end
        
        if vim.api.nvim_buf_is_valid(progress_buf) then
          vim.api.nvim_buf_delete(progress_buf, { force = true })
        end
        
        -- Clean up temporary files
        os.remove(code_file)
        os.remove(script_file)
        -- Don't remove output_file as it might be useful for debugging
      end
      
      timer:stop()
      timeout:stop()
    end)
  end)

  -- Run MATLAB with the script
  local command = config.matlab_executable
  -- Use simpler arguments that are more reliable
  local args = {"-nosplash", "-nodesktop", "-batch", "run('" .. script_file .. "')"} 
  
  -- For macOS, we might need a different approach
  if vim.fn.has('mac') == 1 then
    args = {"-nosplash", "-nodesktop", "-r", "try, run('" .. script_file .. "'); catch e, disp(e.message); end; exit"}
  end
  
  -- Run MATLAB in the background
  local job = Job:new({
    command = command,
    args = args,
    on_stdout = function(_, data)
      if data then
        -- Update progress window with output
        if vim.api.nvim_win_is_valid(progress_win) then
          vim.api.nvim_buf_set_lines(progress_buf, 3, 4, false, {"Latest output: " .. data})
        end
        
        if data:find("MATLAB_NVIM_STARTED") then
          vim.notify("MATLAB process started successfully", vim.log.levels.INFO)
        end
      end
    end,
    on_stderr = function(_, data)
      if data and data ~= "" then
        vim.notify("MATLAB stderr: " .. data, vim.log.levels.WARN)
      end
    end,
    on_exit = function(_, exit_code)
      -- Stop timers
      timer:stop()
      timeout:stop()
      
      -- Close progress window
      if vim.api.nvim_win_is_valid(progress_win) then
        vim.api.nvim_win_close(progress_win, true)
      end
      
      if vim.api.nvim_buf_is_valid(progress_buf) then
        vim.api.nvim_buf_delete(progress_buf, { force = true })
      end
      
      -- Read the output file
      local output = ""
      local success = false
      
      local output_handle = io.open(output_file, 'r')
      if output_handle then
        output = output_handle:read("*all") or ""
        output_handle:close()
        
        -- Check for success or error
        if output:find("MATLAB_NVIM_SUCCESS") then
          success = true
          vim.notify("MATLAB execution completed successfully", vim.log.levels.INFO)
        elseif output:find("MATLAB_NVIM_ERROR") then
          success = false
          vim.notify("MATLAB execution failed with errors", vim.log.levels.ERROR)
        else
          -- If we can't find either marker, check the exit code
          success = (exit_code == 0)
          vim.notify("MATLAB execution completed with exit code: " .. exit_code, vim.log.levels.INFO)
        end
      else
        if exit_code == 0 then
          vim.notify("MATLAB execution completed, but output file not found", vim.log.levels.WARN)
          success = true
        else
          vim.notify("MATLAB execution failed (exit code " .. exit_code .. ") and output file not found", vim.log.levels.ERROR)
          success = false
          output = "Failed to read MATLAB output (exit code " .. exit_code .. ")"
        end
      end
      
      -- Clean up temporary files
      os.remove(code_file)
      os.remove(script_file)
      -- Keep output_file for debugging if execution failed
      if success then
        os.remove(output_file)
      else
        vim.notify("Output file saved at: " .. output_file, vim.log.levels.INFO)
      end
      
      if callback then
        callback(success, output)
      else
        if success then
          -- Show output in a floating window
          M.show_output(output)
        else
          vim.notify("MATLAB execution failed:\n" .. output, vim.log.levels.ERROR)
        end
      end
      
      -- After execution, refresh workspace if it's open
      vim.defer_fn(function()
        local workspace = require('matlab.workspace')
        workspace.refresh()
      end, 1000)
    end,
  })
  
  job:start()
  
  return job
end

-- Show MATLAB output in a floating window
function M.show_output(output)
  -- Create a buffer for the output
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  
  -- Split output into lines
  local lines = {}
  for line in output:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  
  -- Filter out MATLAB_NVIM_SUCCESS line
  local filtered_lines = {}
  for _, line in ipairs(lines) do
    if line ~= "MATLAB_NVIM_SUCCESS" and line ~= "MATLAB_NVIM_STARTED" then
      table.insert(filtered_lines, line)
    end
  end
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, filtered_lines)
  
  -- Calculate window size
  local max_height = math.min(#filtered_lines + 2, 20)
  local max_width = 0
  for _, line in ipairs(filtered_lines) do
    max_width = math.max(max_width, #line)
  end
  max_width = math.min(max_width + 2, 100)
  
  local ui = vim.api.nvim_list_uis()[1]
  
  -- Create floating window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = max_width,
    height = max_height,
    row = math.floor((ui.height - max_height) / 2),
    col = math.floor((ui.width - max_width) / 2),
    style = 'minimal',
    border = 'rounded',
    title = 'MATLAB Output',
    title_pos = 'center',
  })
  
  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'filetype', 'matlab_output')
  
  -- Add close keymap
  vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '', {
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
    noremap = true,
    silent = true,
    desc = "Close MATLAB output window",
  })
  
  -- Add escape keymap
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '', {
    callback = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
    noremap = true,
    silent = true,
    desc = "Close MATLAB output window",
  })
end

-- Execute current cell
function M.execute_cell()
  local cells = require('matlab.cells')
  local cell_text = cells.get_current_cell_text()
  
  if not cell_text then
    vim.notify("Not in a MATLAB cell", vim.log.levels.WARN)
    return
  end
  
  M.execute_code(cell_text)
  
  -- After execution, refresh workspace if it's open
  vim.defer_fn(function()
    local workspace = require('matlab.workspace')
    workspace.refresh()
  end, 1000)
end

-- Execute entire file
function M.execute_file()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local file_text = table.concat(lines, "\n")
  
  M.execute_code(file_text)
  
  -- After execution, refresh workspace if it's open
  vim.defer_fn(function()
    local workspace = require('matlab.workspace')
    workspace.refresh()
  end, 1000)
end

-- Execute selected code
function M.execute_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  local start_line = start_pos[2] - 1
  local start_col = start_pos[3] - 1
  local end_line = end_pos[2] - 1
  local end_col = end_pos[3]
  
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, end_line + 1, false)
  
  -- Adjust first and last line based on columns
  if #lines > 0 then
    if #lines == 1 then
      lines[1] = string.sub(lines[1], start_col + 1, end_col)
    else
      lines[1] = string.sub(lines[1], start_col + 1)
      lines[#lines] = string.sub(lines[#lines], 1, end_col)
    end
  end
  
  local selected_text = table.concat(lines, "\n")
  
  if selected_text == "" then
    vim.notify("No text selected", vim.log.levels.WARN)
    return
  end
  
  M.execute_code(selected_text)
  
  -- After execution, refresh workspace if it's open
  vim.defer_fn(function()
    local workspace = require('matlab.workspace')
    workspace.refresh()
  end, 1000)
end

return M
