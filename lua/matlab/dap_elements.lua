-- MATLAB DAP-UI Elements
-- Implements nvim-dap-ui Element interface for MATLAB debugging
local M = {}
local tmux = require('matlab.tmux')
local utils = require('matlab.utils')

-- Element: MATLAB Variables
-- Shows workspace variables using 'whos' command
M.variables = {}
M.variables._buf = nil
M.variables._last_update = 0

function M.variables.render()
  local buf = M.variables.buffer()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  -- Get variables from MATLAB
  if tmux.exists() then
    tmux.run('whos', false, false)
  end

  local content = {
    'MATLAB Workspace Variables',
    '═════════════════════════',
    '',
    'Use "whos" in MATLAB pane to see detailed variable info',
    '',
    'To inspect a variable:',
    '  • Type variable name in REPL',
    '  • Use disp(varname) for formatted output',
    '  • Use size(varname) for dimensions',
    '',
    'Common commands:',
    '  whos        - List all variables',
    '  who         - List variable names only',
    '  clear var   - Remove variable',
    '  clearvars   - Remove all variables',
  }

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = 'matlab-debug'

  M.variables._last_update = vim.loop.now()
end

function M.variables.buffer()
  if not M.variables._buf or not vim.api.nvim_buf_is_valid(M.variables._buf) then
    M.variables._buf = vim.api.nvim_create_buf(false, true)
    vim.bo[M.variables._buf].buftype = 'nofile'
    vim.bo[M.variables._buf].bufhidden = 'wipe'
    vim.bo[M.variables._buf].swapfile = false
    vim.bo[M.variables._buf].modifiable = false
  end
  return M.variables._buf
end

function M.variables.float_defaults()
  return { width = 80, height = 25 }
end

M.variables.allow_without_session = true

-- Element: MATLAB Call Stack
-- Shows debug call stack using 'dbstack' command
M.callstack = {}
M.callstack._buf = nil
M.callstack._last_update = 0

function M.callstack.render()
  local buf = M.callstack.buffer()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  -- Get call stack from MATLAB
  if tmux.exists() then
    tmux.run('dbstack', false, false)
  end

  local content = {
    'MATLAB Call Stack',
    '══════════════════',
    '',
    'Current execution stack:',
    '(Check MATLAB pane for detailed stack trace)',
    '',
    'Debug commands:',
    '  dbstack     - Show full stack trace',
    '  dbup        - Move up in stack',
    '  dbdown      - Move down in stack',
    '  dbstatus    - Show debugging status',
    '',
    'The stack updates when:',
    '  • Breakpoint is hit',
    '  • Step command executes',
    '  • Function is called/returns',
  }

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = 'matlab-debug'

  M.callstack._last_update = vim.loop.now()
end

function M.callstack.buffer()
  if not M.callstack._buf or not vim.api.nvim_buf_is_valid(M.callstack._buf) then
    M.callstack._buf = vim.api.nvim_create_buf(false, true)
    vim.bo[M.callstack._buf].buftype = 'nofile'
    vim.bo[M.callstack._buf].bufhidden = 'wipe'
    vim.bo[M.callstack._buf].swapfile = false
    vim.bo[M.callstack._buf].modifiable = false
  end
  return M.callstack._buf
end

function M.callstack.float_defaults()
  return { width = 60, height = 20 }
end

M.callstack.allow_without_session = true

-- Element: MATLAB Breakpoints
-- Shows all active breakpoints
M.breakpoints = {}
M.breakpoints._buf = nil
M.breakpoints._last_update = 0

function M.breakpoints.render()
  local buf = M.breakpoints.buffer()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  -- Get breakpoint data from debug module
  local ok, debug_module = pcall(require, 'matlab.debug')
  if not ok then
    return
  end

  local content = {
    'MATLAB Breakpoints',
    '══════════════════',
    ''
  }

  -- List all breakpoints
  local bp_count = 0
  for bufnr, buf_breakpoints in pairs(debug_module.breakpoints) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local filepath = vim.api.nvim_buf_get_name(bufnr)
      local filename = vim.fn.fnamemodify(filepath, ':t')
      local file_header_added = false

      for line in pairs(buf_breakpoints) do
        if not file_header_added then
          table.insert(content, '')
          table.insert(content, filename .. ':')
          file_header_added = true
        end
        table.insert(content, string.format('  • Line %d', line))
        bp_count = bp_count + 1
      end
    end
  end

  if bp_count == 0 then
    table.insert(content, '')
    table.insert(content, 'No breakpoints set')
    table.insert(content, '')
    table.insert(content, 'Set breakpoint: <Leader>mdb')
  else
    table.insert(content, '')
    table.insert(content, string.format('Total: %d breakpoint%s', bp_count, bp_count > 1 and 's' or ''))
  end

  table.insert(content, '')
  table.insert(content, '────────────────────────')
  table.insert(content, 'Commands:')
  table.insert(content, '  :MatlabDebugToggleBreakpoint')
  table.insert(content, '  :MatlabDebugClearBreakpoints')

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = 'matlab-debug'

  M.breakpoints._last_update = vim.loop.now()
end

function M.breakpoints.buffer()
  if not M.breakpoints._buf or not vim.api.nvim_buf_is_valid(M.breakpoints._buf) then
    M.breakpoints._buf = vim.api.nvim_create_buf(false, true)
    vim.bo[M.breakpoints._buf].buftype = 'nofile'
    vim.bo[M.breakpoints._buf].bufhidden = 'wipe'
    vim.bo[M.breakpoints._buf].swapfile = false
    vim.bo[M.breakpoints._buf].modifiable = false
  end
  return M.breakpoints._buf
end

function M.breakpoints.float_defaults()
  return { width = 50, height = 20 }
end

M.breakpoints.allow_without_session = true

-- Element: MATLAB REPL
-- Interactive MATLAB command execution
M.repl = {}
M.repl._buf = nil
M.repl._last_update = 0
M.repl._history = {}

function M.repl.render()
  local buf = M.repl.buffer()
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end

  local content = {
    'MATLAB REPL',
    '═══════════',
    '',
    'Type MATLAB commands and press <CR> to execute',
    'Results appear in the MATLAB pane',
    '',
    'Available commands:',
    '  whos         - Show variables',
    '  dbstack      - Show call stack',
    '  dbcont       - Continue execution',
    '  dbstep       - Step to next line',
    '  dbstep in    - Step into function',
    '  dbstep out   - Step out of function',
    '',
    'Keyboard shortcuts:',
    '  i            - Enter insert mode',
    '  A            - Append at end of line',
    '  <CR>         - Execute current line',
    '',
    '─────────────────────────────',
    ''
  }

  -- Add command history
  if #M.repl._history > 0 then
    table.insert(content, 'Command History:')
    for i = math.max(1, #M.repl._history - 10), #M.repl._history do
      table.insert(content, '> ' .. M.repl._history[i])
    end
    table.insert(content, '')
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = 'matlab'

  -- Set up keymaps for REPL interaction
  M.repl._setup_keymaps(buf)

  M.repl._last_update = vim.loop.now()
end

function M.repl._setup_keymaps(buf)
  local opts = { buffer = buf, noremap = true, silent = true }

  -- Enter insert mode
  vim.keymap.set('n', 'i', function()
    vim.bo[buf].modifiable = true
    vim.cmd.startinsert()
  end, opts)

  -- Append at end
  vim.keymap.set('n', 'A', function()
    vim.bo[buf].modifiable = true
    vim.cmd.startinsert({ bang = true })
  end, opts)

  -- Execute command
  vim.keymap.set('i', '<CR>', function()
    local line = vim.api.nvim_get_current_line()
    if line and line ~= '' and not line:match('^%s*$') and not line:match('^[>─═]') then
      if tmux.exists() then
        tmux.run(line, false, false)
        table.insert(M.repl._history, line)
        -- Refresh to show history
        vim.schedule(function()
          M.repl.render()
        end)
      else
        utils.notify('MATLAB pane not available', vim.log.levels.ERROR)
      end
    end
    vim.cmd.stopinsert()
  end, opts)
end

function M.repl.buffer()
  if not M.repl._buf or not vim.api.nvim_buf_is_valid(M.repl._buf) then
    M.repl._buf = vim.api.nvim_create_buf(false, true)
    vim.bo[M.repl._buf].buftype = 'nofile'
    vim.bo[M.repl._buf].bufhidden = 'wipe'
    vim.bo[M.repl._buf].swapfile = false
    vim.bo[M.repl._buf].modifiable = false
  end
  return M.repl._buf
end

function M.repl.float_defaults()
  return { width = 80, height = 30 }
end

M.repl.allow_without_session = true

-- Helper: Register all elements with nvim-dap-ui
function M.register_all()
  local has_dapui, dapui = pcall(require, 'dapui')
  if not has_dapui then
    utils.notify('nvim-dap-ui not found. Install it to use MATLAB debug UI.', vim.log.levels.WARN)
    return false
  end

  -- Register custom MATLAB elements
  dapui.register_element('matlab_variables', M.variables)
  dapui.register_element('matlab_callstack', M.callstack)
  dapui.register_element('matlab_breakpoints', M.breakpoints)
  dapui.register_element('matlab_repl', M.repl)

  utils.notify('MATLAB debug elements registered with nvim-dap-ui', vim.log.levels.INFO)
  return true
end

-- Helper: Check if dap-ui is available
function M.is_available()
  return pcall(require, 'dapui')
end

return M
