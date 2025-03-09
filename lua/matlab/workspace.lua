-- MATLAB workspace module for displaying workspace variables
local M = {}

-- Dependencies
local has_nui, NuiPopup = pcall(require, 'nui.popup')
local has_plenary, Job = pcall(require, 'plenary.job')

if not has_nui then
  vim.notify("MATLAB.nvim: nui.nvim is required for workspace viewer", vim.log.levels.ERROR)
end

if not has_plenary then
  vim.notify("MATLAB.nvim: plenary.nvim is required for workspace viewer", vim.log.levels.ERROR)
end

-- Store configuration
local config = {}

-- Store UI components
local ui = {
  win = nil,
  buf = nil,
  timer = nil,
}

-- Setup the module
function M.setup(opts)
  config = opts
  
  -- Set up highlight groups
  vim.api.nvim_set_hl(0, 'MatlabWorkspaceHeader', { bold = true, link = 'Title' })
  vim.api.nvim_set_hl(0, 'MatlabWorkspaceVarName', { bold = true, link = 'Identifier' })
  vim.api.nvim_set_hl(0, 'MatlabWorkspaceVarType', { italic = true, link = 'Type' })
  vim.api.nvim_set_hl(0, 'MatlabWorkspaceVarSize', { link = 'Comment' })
  vim.api.nvim_set_hl(0, 'MatlabWorkspaceVarValue', { link = 'String' })
end

-- Toggle workspace viewer
function M.toggle()
  if ui.win and vim.api.nvim_win_is_valid(ui.win) then
    M.close()
  else
    M.open()
  end
end

-- Open workspace viewer
function M.open()
  if ui.win and vim.api.nvim_win_is_valid(ui.win) then
    return
  end
  
  -- Create buffer
  ui.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(ui.buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(ui.buf, 'filetype', 'matlab_workspace')
  
  -- Set up the display based on config
  if config.workspace.position == 'float' then
    -- Create floating window with nui.popup
    if has_nui then
      local popup = NuiPopup({
        enter = false,
        focusable = true,
        border = {
          style = "rounded",
          text = {
            top = " MATLAB Workspace ",
            top_align = "center",
          },
        },
        position = "50%",
        size = {
          width = config.workspace.width,
          height = "60%",
        },
        buf_options = {
          modifiable = false,
          readonly = true,
        },
        win_options = {
          winblend = 10,
          winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
        },
      })
      
      popup:mount()
      ui.win = popup.winid
      
      -- Add close keymap
      vim.api.nvim_buf_set_keymap(popup.bufnr, 'n', 'q', '', {
        callback = function() M.close() end,
        noremap = true,
        silent = true,
        desc = "Close MATLAB workspace viewer",
      })
    end
  else
    -- Create split window
    local position = config.workspace.position == 'right' and 'botright' or 'topleft'
    vim.cmd(position .. ' vertical ' .. config.workspace.width .. ' split')
    ui.win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(ui.win, ui.buf)
    
    -- Set window options
    vim.api.nvim_win_set_option(ui.win, 'number', false)
    vim.api.nvim_win_set_option(ui.win, 'relativenumber', false)
    vim.api.nvim_win_set_option(ui.win, 'cursorline', true)
    vim.api.nvim_win_set_option(ui.win, 'signcolumn', 'no')
    
    -- Add close keymap
    vim.api.nvim_buf_set_keymap(ui.buf, 'n', 'q', '', {
      callback = function() M.close() end,
      noremap = true,
      silent = true,
      desc = "Close MATLAB workspace viewer",
    })
    
    -- Return to previous window
    vim.cmd('wincmd p')
  end
  
  -- Refresh workspace content
  M.refresh()
  
  -- Set up auto-refresh
  if config.workspace.refresh_interval > 0 then
    ui.timer = vim.loop.new_timer()
    ui.timer:start(
      config.workspace.refresh_interval * 1000,
      config.workspace.refresh_interval * 1000,
      vim.schedule_wrap(function()
        M.refresh()
      end)
    )
  end
end

-- Close workspace viewer
function M.close()
  if ui.timer then
    ui.timer:stop()
    ui.timer:close()
    ui.timer = nil
  end
  
  if ui.win and vim.api.nvim_win_is_valid(ui.win) then
    vim.api.nvim_win_close(ui.win, true)
    ui.win = nil
  end
  
  if ui.buf and vim.api.nvim_buf_is_valid(ui.buf) then
    vim.api.nvim_buf_delete(ui.buf, { force = true })
    ui.buf = nil
  end
end

-- Refresh workspace content
function M.refresh()
  if not ui.buf or not vim.api.nvim_buf_is_valid(ui.buf) then
    return
  end
  
  -- Get workspace variables
  M.get_workspace_vars(function(vars)
    if not ui.buf or not vim.api.nvim_buf_is_valid(ui.buf) then
      return
    end
    
    -- Make buffer modifiable
    vim.api.nvim_buf_set_option(ui.buf, 'modifiable', true)
    
    -- Clear buffer
    vim.api.nvim_buf_set_lines(ui.buf, 0, -1, false, {})
    
    -- Add header
    local header = "MATLAB Workspace Variables"
    vim.api.nvim_buf_set_lines(ui.buf, 0, 1, false, { header, string.rep("─", #header), "" })
    vim.api.nvim_buf_add_highlight(ui.buf, -1, 'MatlabWorkspaceHeader', 0, 0, -1)
    
    -- Add variables
    if #vars == 0 then
      vim.api.nvim_buf_set_lines(ui.buf, 3, 4, false, { "No variables in workspace" })
    else
      local line_idx = 3
      for _, var in ipairs(vars) do
        -- Variable name and type
        local name_type = string.format("%s (%s)", var.name, var.type)
        vim.api.nvim_buf_set_lines(ui.buf, line_idx, line_idx + 1, false, { name_type })
        vim.api.nvim_buf_add_highlight(ui.buf, -1, 'MatlabWorkspaceVarName', line_idx, 0, #var.name)
        vim.api.nvim_buf_add_highlight(ui.buf, -1, 'MatlabWorkspaceVarType', line_idx, #var.name + 1, #name_type)
        line_idx = line_idx + 1
        
        -- Size
        local size_str = string.format("  Size: %s", var.size)
        vim.api.nvim_buf_set_lines(ui.buf, line_idx, line_idx + 1, false, { size_str })
        vim.api.nvim_buf_add_highlight(ui.buf, -1, 'MatlabWorkspaceVarSize', line_idx, 0, -1)
        line_idx = line_idx + 1
        
        -- Value (if available)
        if var.value then
          local value_str = string.format("  Value: %s", var.value)
          vim.api.nvim_buf_set_lines(ui.buf, line_idx, line_idx + 1, false, { value_str })
          vim.api.nvim_buf_add_highlight(ui.buf, -1, 'MatlabWorkspaceVarValue', line_idx, 0, -1)
          line_idx = line_idx + 1
        end
        
        -- Empty line between variables
        vim.api.nvim_buf_set_lines(ui.buf, line_idx, line_idx + 1, false, { "" })
        line_idx = line_idx + 1
      end
    end
    
    -- Make buffer non-modifiable again
    vim.api.nvim_buf_set_option(ui.buf, 'modifiable', false)
  end)
end

-- Get workspace variables
function M.get_workspace_vars(callback)
  if not has_plenary then
    callback({})
    return
  end
  
  -- Create a MATLAB script to get workspace info
  local temp_file = vim.fn.tempname() .. '.m'
  local script = [[
    % Get workspace variables
    vars = whos;
    
    % Open file for writing
    fid = fopen(']] .. temp_file .. [[', 'w');
    
    % For each variable, write info
    for i = 1:length(vars)
        var = vars(i);
        fprintf(fid, 'NAME: %s\n', var.name);
        fprintf(fid, 'TYPE: %s\n', var.class);
        fprintf(fid, 'SIZE: %s\n', mat2str(var.size));
        
        % Try to get value for small variables
        if var.bytes < 1000 && ~strcmp(var.class, 'function_handle')
            try
                val = evalin('base', var.name);
                if ischar(val)
                    val_str = val;
                elseif isnumeric(val) && numel(val) <= 10
                    val_str = mat2str(val);
                elseif islogical(val) && numel(val) <= 10
                    val_str = mat2str(val);
                else
                    val_str = '<large value>';
                end
                fprintf(fid, 'VALUE: %s\n', val_str);
            catch
                fprintf(fid, 'VALUE: <cannot display>\n');
            end
        end
        
        fprintf(fid, '---\n');
    end
    
    % Close file
    fclose(fid);
    
    % Exit MATLAB
    exit;
  ]]
  
  local script_file = vim.fn.tempname() .. '.m'
  local f = io.open(script_file, 'w')
  f:write(script)
  f:close()
  
  -- Run MATLAB with the script
  local command = config.matlab_executable
  local args = {"-nosplash", "-nodesktop", "-r", "run('" .. script_file .. "')"}
  
  -- Run MATLAB in the background
  Job:new({
    command = command,
    args = args,
    on_exit = function(_, exit_code)
      -- Read the output file
      if exit_code == 0 then
        local output_file = io.open(temp_file, 'r')
        if not output_file then
          vim.notify("Failed to read MATLAB workspace data", vim.log.levels.ERROR)
          callback({})
          return
        end
        
        local vars = {}
        local current_var = nil
        
        for line in output_file:lines() do
          if line:match("^NAME: ") then
            if current_var then
              table.insert(vars, current_var)
            end
            current_var = { name = line:sub(7) }
          elseif line:match("^TYPE: ") and current_var then
            current_var.type = line:sub(7)
          elseif line:match("^SIZE: ") and current_var then
            current_var.size = line:sub(7)
          elseif line:match("^VALUE: ") and current_var then
            current_var.value = line:sub(8)
          elseif line == "---" and current_var then
            table.insert(vars, current_var)
            current_var = nil
          end
        end
        
        if current_var then
          table.insert(vars, current_var)
        end
        
        output_file:close()
        
        -- Clean up temporary files
        os.remove(temp_file)
        os.remove(script_file)
        
        callback(vars)
      else
        vim.notify("MATLAB execution failed", vim.log.levels.ERROR)
        callback({})
      end
    end,
  }):start()
end

return M
