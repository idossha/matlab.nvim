-- Cell execution functionality for matlab.nvim
local M = {}
local tmux = require('matlab.tmux')
local commands = require('matlab.commands')

-- Store fold state for cells
M.folded_cells = {}

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
  
  -- Execute the code
  vim.cmd('write')
  tmux.run(code)
end

-- Execute from the start to current cell
function M.execute_to_cell()
  if not commands.is_matlab_script() then
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
  
  -- Execute the code
  vim.cmd('write')
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

-- Fold or unfold a specific cell
function M.toggle_cell_fold(cell_idx)
  if not cell_idx then
    -- If no cell index provided, find the current cell
    local current_line = vim.fn.line('.')
    local all_cells = M.get_all_cells()
    
    for i, cell in ipairs(all_cells) do
      if current_line >= cell.start and current_line <= cell.ending then
        cell_idx = i
        break
      end
    end
    
    if not cell_idx then return end
  end
  
  local all_cells = M.get_all_cells()
  local cell = all_cells[cell_idx]
  
  if not cell then return end
  
  -- Generate a unique key for this cell based on its content
  local cell_key = cell.start .. "_" .. cell.ending
  
  -- Toggle fold state
  if M.folded_cells[cell_key] then
    -- Unfold
    vim.cmd(cell.start .. "," .. cell.ending .. "foldopen")
    M.folded_cells[cell_key] = nil
  else
    -- Fold
    vim.cmd(cell.start+1 .. "," .. cell.ending .. "fold")
    M.folded_cells[cell_key] = true
  end
end

-- Fold or unfold all cells
function M.toggle_all_cell_folds()
  local all_cells = M.get_all_cells()
  local any_folded = false
  
  -- Check if any cells are folded
  for _, cell in ipairs(all_cells) do
    local cell_key = cell.start .. "_" .. cell.ending
    if M.folded_cells[cell_key] then
      any_folded = true
      break
    end
  end
  
  -- If any are folded, unfold all; otherwise fold all
  if any_folded then
    -- Unfold all
    for _, cell in ipairs(all_cells) do
      local cell_key = cell.start .. "_" .. cell.ending
      if M.folded_cells[cell_key] then
        vim.cmd(cell.start .. "," .. cell.ending .. "foldopen")
        M.folded_cells[cell_key] = nil
      end
    end
  else
    -- Fold all
    for _, cell in ipairs(all_cells) do
      local cell_key = cell.start .. "_" .. cell.ending
      -- Don't fold the cell marker line
      vim.cmd(cell.start+1 .. "," .. cell.ending .. "fold")
      M.folded_cells[cell_key] = true
    end
  end
end

-- Format the current cell for readability
function M.format_current_cell()
  local start_line, end_line = M.find_current_cell()
  if start_line >= end_line then return end
  
  -- Use MATLAB's built-in formatter through the tmux pane
  -- This is a placeholder that could be implemented in the future
  vim.notify("Cell formatting is not implemented yet.", vim.log.levels.INFO)
end

return M