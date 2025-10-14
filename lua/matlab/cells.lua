-- /lua/matlab/cells.lua
-- Cell execution functionality for matlab.nvim
local M = {}
local tmux = require('matlab.tmux')
local commands = require('matlab.commands')

-- Find the boundaries of the current cell
function M.find_current_cell()
  local current_line = vim.fn.line('.')
  local start_line = current_line
  local end_line = current_line
  local buffer_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  
  -- Search backwards for cell marker (%%...)
  while start_line > 1 do
    start_line = start_line - 1
    local line = buffer_lines[start_line]
    if line and line:match('^%s*%%%%') then
      break
    end
  end
  
  -- Search forwards for next cell marker (%%...)
  while end_line < #buffer_lines do
    end_line = end_line + 1
    local line = buffer_lines[end_line]
    if line and line:match('^%s*%%%%') then
      end_line = end_line - 1
      break
    end
  end
  
  return start_line, end_line
end

-- Execute the current cell
function M.execute_current_cell()
  if not commands.is_matlab_script() then
    return
  end
  
  if not tmux.exists() then
    return
  end
  
  local start_line, end_line = M.find_current_cell()
  
  -- Get cell content
  local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)
  
  -- Filter out comment-only lines and empty lines
  local code_lines = {}
  for _, line in ipairs(lines) do
    -- Skip lines that only contain comments or are empty
    if not line:match('^%s*%%') and not line:match('^%s*$') then
      table.insert(code_lines, line)
    end
  end
  
  if #code_lines == 0 then
    vim.notify('No executable code found in this cell.', vim.log.levels.WARN)
    return
  end
  
  -- Join lines and escape for MATLAB execution
  local code = table.concat(code_lines, '\n')
  
  -- Save file before executing
  if vim.bo.modified then
    local ok, err = pcall(vim.cmd, 'write')
    if not ok then
      vim.notify('Failed to save file: ' .. tostring(err), vim.log.levels.ERROR)
      return
    end
  end
  
  tmux.run(code)
end

-- Execute from the start to current cell
function M.execute_to_cell()
  if not commands.is_matlab_script() then
    return
  end
  
  if not tmux.exists() then
    return
  end
  
  local _, end_line = M.find_current_cell()
  
  -- Get content from start to current cell
  local lines = vim.api.nvim_buf_get_lines(0, 0, end_line + 1, false)
  
  -- Filter out comment-only lines and empty lines
  local code_lines = {}
  for _, line in ipairs(lines) do
    -- Skip lines that only contain comments or are empty
    if not line:match('^%s*%%') and not line:match('^%s*$') then
      table.insert(code_lines, line)
    end
  end
  
  if #code_lines == 0 then
    vim.notify('No executable code found.', vim.log.levels.WARN)
    return
  end
  
  -- Join lines and escape for MATLAB execution
  local code = table.concat(code_lines, '\n')
  
  -- Save file before executing
  if vim.bo.modified then
    local ok, err = pcall(vim.cmd, 'write')
    if not ok then
      vim.notify('Failed to save file: ' .. tostring(err), vim.log.levels.ERROR)
      return
    end
  end
  
  tmux.run(code)
end

-- Get all cell boundaries in the current buffer
function M.get_all_cells()
  local buffer_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local cells = {}
  local start_line = 1
  
  -- Add first cell if it doesn't start with cell marker
  if not buffer_lines[1] or not buffer_lines[1]:match('^%s*%%%%') then
    table.insert(cells, { start = 1, title = "Beginning of file" })
  end
  
  -- Find all cell markers
  for i, line in ipairs(buffer_lines) do
    if line:match('^%s*%%%%') then
      -- Extract cell title from the cell marker line
      local title = line:match('^%s*%%%%(.*)$') or ""
      title = title:gsub("^%s*(.-)%s*$", "%1") -- trim whitespace
      if title == "" then title = "Untitled cell" end
      
      table.insert(cells, { start = i, title = title })
    end
  end
  
  -- Calculate end lines for each cell
  for i = 1, #cells - 1 do
    cells[i].ending = cells[i+1].start - 1
  end
  
  -- Set the end line for the last cell
  if #cells > 0 then
    cells[#cells].ending = #buffer_lines
  end
  
  return cells
end

-- Fold or unfold the current cell - simpler, more direct implementation
function M.toggle_cell_fold()
  -- Find the current cell boundaries
  local start_line, end_line = M.find_current_cell()
  
  -- Ensure we have valid boundaries
  if not start_line or not end_line or start_line >= end_line then
    vim.notify("No valid cell found at cursor position", vim.log.levels.WARN)
    return
  end
  
  -- Check if the cell is already folded by checking its first line
  local is_folded = vim.fn.foldclosed(start_line + 1) > 0
  
  if is_folded then
    -- If folded, unfold it using try-catch to avoid errors when no folds exist
    pcall(function()
      -- Use a targeted unfold approach that's less error-prone
      for i = start_line, end_line do
        if vim.fn.foldclosed(i) > 0 then
          vim.cmd(i .. " normal! zo")
        end
      end
    end)
    
    -- Only notify if notifications aren't set to minimal
    if not require('matlab.config').get('minimal_notifications') then
      vim.notify("Cell unfolded", vim.log.levels.INFO)
    end
  else
    -- If not folded, fold it - but leave the cell marker (%%...) line visible
    if start_line > 0 then
      vim.cmd((start_line+1) .. "," .. end_line .. " fold")
      
      -- Only notify if notifications aren't set to minimal
      if not require('matlab.config').get('minimal_notifications') then
        vim.notify("Cell folded", vim.log.levels.INFO)
      end
    end
  end
end

-- Fold or unfold all cells
function M.toggle_all_cell_folds()
  local all_cells = M.get_all_cells()
  local any_folded = false
  
  -- Check if any cells are folded
  for _, cell in ipairs(all_cells) do
    for i = cell.start, cell.ending do
      if vim.fn.foldclosed(i) > 0 then
        any_folded = true
        break
      end
    end
    if any_folded then break end
  end
  
  if any_folded then
    -- Unfold all cells
    pcall(function()
      for _, cell in ipairs(all_cells) do
        for i = cell.start, cell.ending do
          if vim.fn.foldclosed(i) > 0 then
            vim.cmd(i .. " normal! zo")
          end
        end
      end
    end)
    
    -- Only notify if notifications aren't set to minimal
    if not require('matlab.config').get('minimal_notifications') then
      vim.notify("All cells unfolded", vim.log.levels.INFO)
    end
  else
    -- Fold all cells
    for _, cell in ipairs(all_cells) do
      -- Don't fold the cell marker line
      if cell.start < cell.ending then
        vim.cmd((cell.start+1) .. "," .. cell.ending .. " fold")
      end
    end
    
    -- Only notify if notifications aren't set to minimal
    if not require('matlab.config').get('minimal_notifications') then
      vim.notify("All cells folded", vim.log.levels.INFO)
    end
  end
end

return M
