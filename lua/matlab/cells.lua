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

return M