-- MATLAB Debug UI
-- Provides split windows for debug information with event-driven updates
local M = {}
local tmux = require('matlab.tmux')
local utils = require('matlab.utils')

-- UI state
M.windows = {}
M.buffers = {}
M.initialized = false

-- Configuration
M.config = {
  sidebar_width = 40,
  sidebar_position = 'right', -- 'left' or 'right'
}

-- Load configuration
function M.load_config()
  local ok, config = pcall(require, 'matlab.config')
  if ok then
    local ui_config = config.get('debug_ui')
    if ui_config and type(ui_config) == 'table' then
      M.config.sidebar_width = ui_config.sidebar_width or M.config.sidebar_width
      M.config.sidebar_position = ui_config.sidebar_position or M.config.sidebar_position
    end
  end
end

-- Helper: create a scratch buffer
local function create_scratch_buffer(name)
  local buf = vim.api.nvim_create_buf(false, true)
  
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'hide'
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = 'matlab-debug'
  
  -- Set buffer name safely
  pcall(vim.api.nvim_buf_set_name, buf, 'matlab://' .. name)
  
  return buf
end

-- Helper: set content in buffer
local function set_buffer_content(buf, lines)
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines or {})
  vim.bo[buf].modifiable = false
  return true
end

-- Helper: set common window options
local function set_window_options(win)
  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].cursorline = true
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].foldcolumn = '0'
  vim.wo[win].winfixwidth = true
end

-- Parse call stack from MATLAB pane
function M.get_callstack()
  local pane = tmux.get_server_pane()
  if not pane then
    return {}
  end

  local ok, output = pcall(tmux.execute, 'capture-pane -t ' .. vim.fn.shellescape(pane) .. ' -p -S -20')
  if not ok or not output then
    return {}
  end

  local lines = vim.split(output, '\n')
  local stack = {}

  for i = #lines, 1, -1 do
    local line = lines[i]
    
    -- Match stack frame: "> In filename (line X)" or "In filename (line X)"
    local marker, filename, linenum = line:match('^(%>?)%s*In%s+([^%(]+)%(line%s+(%d+)%)')
    if filename then
      table.insert(stack, 1, {
        current = marker == '>',
        file = vim.trim(filename),
        line = tonumber(linenum)
      })
    end
    
    -- Stop at prompt
    if line:match('^[K]?>>') and #stack > 0 then
      break
    end
  end

  return stack
end

-- Get breakpoints from debug module
function M.get_breakpoints()
  local ok, debug_module = pcall(require, 'matlab.debug')
  if not ok then
    return {}
  end

  local breakpoints = {}
  for bufnr, buf_bps in pairs(debug_module.breakpoints) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local filepath = vim.api.nvim_buf_get_name(bufnr)
      local filename = vim.fn.fnamemodify(filepath, ':t')
      
      for line in pairs(buf_bps) do
        table.insert(breakpoints, { file = filename, line = line })
      end
    end
  end

  -- Sort by filename then line
  table.sort(breakpoints, function(a, b)
    if a.file == b.file then
      return a.line < b.line
    end
    return a.file < b.file
  end)

  return breakpoints
end

-- Format call stack for display
local function format_callstack(stack)
  local lines = { '── Call Stack ──', '' }
  
  if #stack == 0 then
    table.insert(lines, '  (not in debug mode)')
  else
    for _, frame in ipairs(stack) do
      local marker = frame.current and '▶ ' or '  '
      table.insert(lines, string.format('%s%s:%d', marker, frame.file, frame.line))
    end
  end
  
  return lines
end

-- Format breakpoints for display
local function format_breakpoints(breakpoints)
  local lines = { '── Breakpoints ──', '' }
  
  if #breakpoints == 0 then
    table.insert(lines, '  (none set)')
  else
    for _, bp in ipairs(breakpoints) do
      table.insert(lines, string.format('  ● %s:%d', bp.file, bp.line))
    end
  end
  
  return lines
end

-- Create or get the sidebar buffer
function M.get_sidebar_buffer()
  if M.buffers.sidebar and vim.api.nvim_buf_is_valid(M.buffers.sidebar) then
    return M.buffers.sidebar
  end
  
  local buf = create_scratch_buffer('debug-sidebar')
  M.buffers.sidebar = buf
  
  -- Set keymaps
  local opts = { buffer = buf, noremap = true, silent = true }
  vim.keymap.set('n', 'q', M.close_sidebar, opts)
  vim.keymap.set('n', 'r', M.refresh, opts)
  vim.keymap.set('n', '<CR>', M.jump_to_location, opts)
  
  return buf
end

-- Jump to location under cursor (for stack frames and breakpoints)
function M.jump_to_location()
  local line = vim.api.nvim_get_current_line()
  
  -- Try to match file:line pattern
  local file, linenum = line:match('([%w_]+%.m):(%d+)')
  if not file or not linenum then
    file, linenum = line:match('([%w_]+):(%d+)')
  end
  
  if file and linenum then
    -- Find buffer with this file
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        if bufname:match(file .. '$') or bufname:match(file:gsub('%.m$', '') .. '%.m$') then
          -- Find a window showing this buffer, or use first non-sidebar window
          local wins = vim.fn.win_findbuf(bufnr)
          if #wins > 0 then
            vim.api.nvim_set_current_win(wins[1])
          else
            -- Find first non-sidebar window
            for _, win in ipairs(vim.api.nvim_list_wins()) do
              if win ~= M.windows.sidebar then
                vim.api.nvim_set_current_win(win)
                vim.api.nvim_win_set_buf(win, bufnr)
                break
              end
            end
          end
          vim.api.nvim_win_set_cursor(vim.api.nvim_get_current_win(), { tonumber(linenum), 0 })
          return
        end
      end
    end
    utils.notify('File not found: ' .. file, vim.log.levels.WARN)
  end
end

-- Refresh sidebar content (called on debug events)
function M.refresh()
  local buf = M.buffers.sidebar
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local ok, debug_module = pcall(require, 'matlab.debug')
  local is_debugging = ok and debug_module.debug_active

  local lines = {}
  
  -- Header
  local status = is_debugging and '🔴 DEBUGGING' or '⚪ IDLE'
  table.insert(lines, status)
  table.insert(lines, string.rep('═', 38))
  table.insert(lines, '')
  
  -- Call Stack
  local stack = M.get_callstack()
  vim.list_extend(lines, format_callstack(stack))
  table.insert(lines, '')
  
  -- Breakpoints
  local bps = M.get_breakpoints()
  vim.list_extend(lines, format_breakpoints(bps))
  table.insert(lines, '')
  
  -- Help
  table.insert(lines, '── Keys ──')
  table.insert(lines, '  r = refresh')
  table.insert(lines, '  q = close')
  table.insert(lines, '  <CR> = jump to location')
  table.insert(lines, '')
  table.insert(lines, '<Leader>mW = refresh workspace')
  
  set_buffer_content(buf, lines)
end

-- Open the debug sidebar
function M.open_sidebar()
  -- Don't create duplicate
  if M.windows.sidebar and vim.api.nvim_win_is_valid(M.windows.sidebar) then
    M.refresh()
    return
  end

  local buf = M.get_sidebar_buffer()
  
  -- Create split
  local split_cmd = M.config.sidebar_position == 'left' and 'topleft' or 'botright'
  vim.cmd(split_cmd .. ' vertical ' .. M.config.sidebar_width .. 'split')
  
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  M.windows.sidebar = win
  
  set_window_options(win)
  
  -- Go back to previous window
  vim.cmd('wincmd p')
  
  -- Initial refresh
  M.refresh()
end

-- Close the sidebar
function M.close_sidebar()
  if M.windows.sidebar and vim.api.nvim_win_is_valid(M.windows.sidebar) then
    vim.api.nvim_win_close(M.windows.sidebar, true)
    M.windows.sidebar = nil
  end
end

-- Toggle sidebar
function M.toggle_sidebar()
  if M.windows.sidebar and vim.api.nvim_win_is_valid(M.windows.sidebar) then
    M.close_sidebar()
  else
    M.open_sidebar()
  end
end

-- Check if sidebar is open
function M.is_open()
  return M.windows.sidebar and vim.api.nvim_win_is_valid(M.windows.sidebar)
end

-- Update all (called from debug module on events)
function M.update_all()
  if M.is_open() then
    vim.schedule(function()
      M.refresh()
    end)
  end
end

-- Setup
function M.setup()
  if M.initialized then
    return
  end
  
  M.load_config()
  M.initialized = true
end

return M
