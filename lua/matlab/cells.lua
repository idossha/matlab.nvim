-- MATLAB cells module for handling cell rendering and navigation
local M = {}

-- Namespace for cell markers
local ns_id = vim.api.nvim_create_namespace('matlab_cells')

-- Store configuration
local config = {}

-- Setup the module
function M.setup(opts)
  config = opts
end

-- Find all cell boundaries in a buffer
-- Returns a table of { line = line_number, title = cell_title }
function M.find_cells(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local cells = {}

  for i, line in ipairs(lines) do
    if line:match("^%%") then
      local title = line:match("^%%%%?%s*(.*)$")
      table.insert(cells, { line = i - 1, title = title or "" })
    end
  end

  return cells
end

-- Apply cell highlighting to the current buffer
function M.apply_highlighting()
  local bufnr = vim.api.nvim_get_current_buf()
  
  -- Clear existing markers
  vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
  
  -- Find cells
  local cells = M.find_cells(bufnr)
  
  -- Get buffer width for full-width separator
  local width = vim.api.nvim_win_get_width(0)
  local separator_length = config.cell_separator.length > 0 
    and config.cell_separator.length 
    or width - 1
  
  -- Create separator string
  local separator = string.rep(config.cell_separator.char, separator_length)
  
  -- Apply highlighting for each cell
  for _, cell in ipairs(cells) do
    -- Add the separator line
    vim.api.nvim_buf_set_extmark(bufnr, ns_id, cell.line, 0, {
      virt_text = {{separator, "MatlabCellSeparator"}},
      virt_text_pos = "overlay",
    })
    
    -- Bold the cell title
    local line_text = vim.api.nvim_buf_get_lines(bufnr, cell.line, cell.line + 1, false)[1]
    local title_start = line_text:find("%%") + 2
    
    if title_start and cell.title and #cell.title > 0 then
      -- Skip any additional '%' characters and spaces
      while line_text:sub(title_start, title_start) == "%" or line_text:sub(title_start, title_start) == " " do
        title_start = title_start + 1
      end
      
      -- Apply highlighting to the title
      vim.api.nvim_buf_add_highlight(bufnr, ns_id, "MatlabCellTitle", cell.line, title_start - 1, -1)
    end
  end
end

-- Navigate to the next cell
function M.goto_next_cell()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1] - 1
  
  local cells = M.find_cells(bufnr)
  
  for _, cell in ipairs(cells) do
    if cell.line > current_line then
      vim.api.nvim_win_set_cursor(0, {cell.line + 1, 0})
      vim.cmd("normal! zz")
      return
    end
  end
  
  vim.notify("No next MATLAB cell found", vim.log.levels.INFO)
end

-- Navigate to the previous cell
function M.goto_prev_cell()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1] - 1
  
  local cells = M.find_cells(bufnr)
  local prev_cell = nil
  
  for _, cell in ipairs(cells) do
    if cell.line >= current_line then
      break
    end
    prev_cell = cell
  end
  
  if prev_cell then
    vim.api.nvim_win_set_cursor(0, {prev_cell.line + 1, 0})
    vim.cmd("normal! zz")
  else
    vim.notify("No previous MATLAB cell found", vim.log.levels.INFO)
  end
end

-- Find the current cell (returns start line, end line, and title)
function M.get_current_cell()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1] - 1
  
  local cells = M.find_cells(bufnr)
  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  
  -- Find the cell containing the current line
  local cell_start, cell_title
  local cell_end = total_lines - 1
  
  for i, cell in ipairs(cells) do
    if cell.line > current_line then
      cell_end = cell.line - 1
      break
    elseif cell.line <= current_line then
      cell_start = cell.line
      cell_title = cell.title
    end
  end
  
  if not cell_start then
    return nil
  end
  
  return {
    start_line = cell_start,
    end_line = cell_end,
    title = cell_title
  }
end

-- Get the text of the current cell
function M.get_current_cell_text()
  local cell = M.get_current_cell()
  
  if not cell then
    vim.notify("Not in a MATLAB cell", vim.log.levels.WARN)
    return nil
  end
  
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, cell.start_line, cell.end_line + 1, false)
  
  return table.concat(lines, "\n")
end

return M
