-- MATLAB Debugging UI
-- Provides floating windows for debugging information
local M = {}
local tmux = require('matlab.tmux')
local utils = require('matlab.utils')

-- UI state
M.windows = {}
M.buffers = {}

-- Default window configurations
local DEFAULT_CONFIG = {
  variables = { position = 'right', size = 0.3 },
  callstack = { position = 'bottom', size = 0.3 },
  breakpoints = { position = 'left', size = 0.25 },
  repl = { position = 'bottom', size = 0.4 },
  controls = { position = 'top', size = 0.3 }
}

M.config = vim.deepcopy(DEFAULT_CONFIG)

-- Load configuration from matlab.config
function M.load_config()
  local ok, config = pcall(require, 'matlab.config')
  if not ok then
    return
  end

  local ui_config = config.get('debug_ui')
  if not ui_config or type(ui_config) ~= 'table' then
    return
  end

  -- Merge user config with defaults
  for name, default_cfg in pairs(DEFAULT_CONFIG) do
    local pos_key = name .. '_position'
    local size_key = name .. '_size'
    M.config[name].position = ui_config[pos_key] or default_cfg.position
    M.config[name].size = ui_config[size_key] or default_cfg.size
  end
end

-- Helper: set buffer options with modern API
local function set_buffer_options(buf, name, title)
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false

  -- Set buffer name safely
  local ok, _ = pcall(vim.api.nvim_buf_set_name, buf, 'matlab-debug://' .. name)
  if not ok then
    -- If name already exists, append timestamp
    vim.api.nvim_buf_set_name(buf, 'matlab-debug://' .. name .. '-' .. os.time())
  end
end

-- Helper: set window options with modern API
local function set_window_options(win)
  vim.wo[win].wrap = false
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  vim.wo[win].cursorline = true
  vim.wo[win].signcolumn = 'no'
  vim.wo[win].foldcolumn = '0'
end

-- Helper: set window keymaps
local function set_window_keymaps(buf, name)
  local opts = { buffer = buf, noremap = true, silent = true }
  local close_fn = function() M.close_window(name) end

  vim.keymap.set('n', 'q', close_fn, opts)
  vim.keymap.set('n', '<Esc>', close_fn, opts)
  vim.keymap.set('n', '<C-c>', close_fn, opts)
end

-- Create a floating window
function M.create_window(name, title, content_lines)
  -- Close existing window if it exists
  M.close_window(name)

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  M.buffers[name] = buf

  -- Set buffer content
  local lines = content_lines and #content_lines > 0 and content_lines or { title, '', 'Loading...' }
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  -- Set buffer options
  set_buffer_options(buf, name, title)

  -- Calculate window position and size
  local win_config = M.get_window_config(name, title)
  if not win_config then
    utils.notify('Invalid window configuration for ' .. name, vim.log.levels.ERROR)
    return nil, nil
  end

  -- Create window
  local ok, win = pcall(vim.api.nvim_open_win, buf, false, win_config)
  if not ok then
    utils.notify('Failed to create window: ' .. tostring(win), vim.log.levels.ERROR)
    return nil, nil
  end

  M.windows[name] = win

  -- Set window options and keymaps
  set_window_options(win)
  set_window_keymaps(buf, name)

  return win, buf
end

-- Get window configuration based on position
function M.get_window_config(name, title)
  local cfg = M.config[name]
  if not cfg then
    return nil
  end

  local screen_width = vim.o.columns
  local screen_height = vim.o.lines

  -- Common config
  local base_config = {
    relative = 'editor',
    style = 'minimal',
    border = 'rounded',
    title = ' ' .. title .. ' ',
    title_pos = 'center'
  }

  -- Position-specific config
  local positions = {
    right = {
      width = math.floor(screen_width * cfg.size),
      height = screen_height - 4,
      col = screen_width - math.floor(screen_width * cfg.size),
      row = 0,
    },
    left = {
      width = math.floor(screen_width * cfg.size),
      height = screen_height - 4,
      col = 0,
      row = 0,
    },
    bottom = {
      width = screen_width - 4,
      height = math.floor(screen_height * cfg.size),
      col = 2,
      row = screen_height - math.floor(screen_height * cfg.size) - 2,
    },
    top = {
      width = screen_width - 4,
      height = math.floor(screen_height * cfg.size),
      col = 2,
      row = 1,
    },
  }

  local pos_config = positions[cfg.position]
  if not pos_config then
    return nil
  end

  return vim.tbl_extend('force', base_config, pos_config)
end

-- Close a specific window
function M.close_window(name)
  local win = M.windows[name]
  if win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
    M.windows[name] = nil
  end

  local buf = M.buffers[name]
  if buf and vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    M.buffers[name] = nil
  end
end

-- Close all debug windows
function M.close_all()
  for name in pairs(M.windows) do
    M.close_window(name)
  end
end

-- Update a window's content
function M.update_window(name, content_lines)
  local buf = M.buffers[name]
  if not buf or not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  local lines = content_lines or { 'No data available' }
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  return true
end

-- Helper: check if MATLAB is available
local function check_matlab_available()
  if not tmux.exists() then
    utils.notify('MATLAB pane not available.', vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Parse workspace variables from MATLAB output
local function parse_workspace_variables()
  local pane = tmux.get_server_pane()
  if not pane then
    utils.log('No tmux pane available for parsing variables', 'DEBUG')
    return nil
  end

  -- Run whos command and capture output
  tmux.run('whos', true, false)

  -- Wait for MATLAB to process and then capture
  local ok, output = pcall(function()
    -- Small delay to let MATLAB process
    vim.wait(300, function() return false end)
    return tmux.execute('capture-pane -t ' .. vim.fn.shellescape(pane) .. ' -p -S -30')
  end)
  
  if not ok or not output then
    utils.log('Failed to capture pane output for variables', 'DEBUG')
    return nil
  end

  -- Split into lines and find the most recent whos output
  local lines = vim.split(output, '\n')
  local variables = {}
  local seen_names = {}  -- Track seen variable names to avoid duplicates
  local in_whos_output = false
  local header_found = false
  
  -- Search from bottom to top to find the most recent whos output
  for i = #lines, 1, -1 do
    local line = lines[i]
    
    -- Detect the header line of whos output
    if line:match('^%s*Name%s+Size%s+Bytes%s+Class') then
      header_found = true
      in_whos_output = true
      break  -- Found the header, now we can stop and use collected variables
    end
    
    -- Match variable lines (before we find header, searching backwards)
    -- Format: "  varname      1x1                 8  double"
    local name, size, bytes, class = line:match('^%s*([%w_]+)%s+([%dx]+)%s+(%d+)%s+(%w+)')
    if name and name ~= 'Name' and not seen_names[name] then
      seen_names[name] = true
      table.insert(variables, 1, {  -- Insert at beginning since we're going backwards
        name = name,
        size = size,
        bytes = bytes,
        class = class
      })
    end
    
    -- Stop if we hit a prompt line (K>> or >>)
    if line:match('^[K]?>>') and #variables > 0 then
      break
    end
  end

  utils.log('Parsed ' .. #variables .. ' workspace variables', 'DEBUG')
  return variables
end

-- Show variables window
function M.show_variables()
  if not check_matlab_available() then
    return
  end

  local content = {
    'MATLAB Variables',
    '═══════════════',
    '',
    'Loading workspace variables...',
  }

  M.create_window('variables', 'Variables', content)

  -- Update with actual variables after a delay
  vim.defer_fn(function()
    local variables = parse_workspace_variables()

    local updated_content = {
      'MATLAB Variables',
      '═══════════════',
      '',
    }

    if variables and #variables > 0 then
      table.insert(updated_content, string.format('%-20s %-12s %-10s %s', 'Name', 'Size', 'Bytes', 'Class'))
      table.insert(updated_content, string.rep('─', 60))

      for _, var in ipairs(variables) do
        table.insert(updated_content, string.format('%-20s %-12s %-10s %s',
          var.name, var.size, var.bytes, var.class))
      end
    else
      table.insert(updated_content, 'No variables in workspace')
    end

    table.insert(updated_content, '')
    table.insert(updated_content, 'Press r to refresh, q to close')

    M.update_window('variables', updated_content)

    -- Add refresh keymap
    local buf = M.buffers['variables']
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.keymap.set('n', 'r', M.show_variables, { buffer = buf, noremap = true, silent = true })
    end
  end, 400)
end

-- Show call stack window
function M.show_callstack()
  if not check_matlab_available() then
    return
  end

  -- Trigger MATLAB command to display call stack
  tmux.run('dbstack', false, false)

  local content = {
    'MATLAB Call Stack',
    '═══════════════',
    '',
    'Current execution stack:',
    '(Check MATLAB pane for current stack)',
    '',
    'Stack will update during debugging',
    '',
    'Press q, <Esc>, or <C-c> to close'
  }

  M.create_window('callstack', 'Call Stack', content)
end

-- Show breakpoints window
function M.show_breakpoints()
  local ok, debug_module = pcall(require, 'matlab.debug')
  if not ok then
    utils.notify('Failed to load debug module.', vim.log.levels.ERROR)
    return
  end

  local content = {
    'MATLAB Breakpoints',
    '═══════════════',
    ''
  }

  -- List current breakpoints
  local bp_count = 0
  for bufnr, buf_breakpoints in pairs(debug_module.breakpoints) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local filepath = vim.api.nvim_buf_get_name(bufnr)
      local filename = vim.fn.fnamemodify(filepath, ':t')

      for line in pairs(buf_breakpoints) do
        table.insert(content, string.format('  %s:%d', filename, line))
        bp_count = bp_count + 1
      end
    end
  end

  if bp_count == 0 then
    table.insert(content, 'No breakpoints set')
  end

  table.insert(content, '')
  table.insert(content, 'Commands:')
  table.insert(content, '  :MatlabDebugToggleBreakpoint')
  table.insert(content, '  :MatlabDebugClearBreakpoints')
  table.insert(content, '')
  table.insert(content, 'Press q, <Esc>, or <C-c> to close')

  M.create_window('breakpoints', 'Breakpoints', content)
end

-- Show REPL window
function M.show_repl()
  if not check_matlab_available() then
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
    '  whos        - Show variables',
    '  dbstack     - Show call stack',
    '  dbcont      - Continue execution',
    '  dbstep      - Step through code',
    '',
    'Press i to enter insert mode',
    'Press q, <Esc>, or <C-c> to close',
    '',
    '─────────────────────────────',
    ''
  }

  local win, buf = M.create_window('repl', 'REPL', content)
  if not win or not buf then
    return
  end

  -- REPL-specific keymaps
  local opts = { buffer = buf, noremap = true, silent = true }

  vim.keymap.set('n', 'i', function()
    vim.bo[buf].modifiable = true
    vim.cmd.startinsert()
  end, opts)

  vim.keymap.set('n', 'A', function()
    vim.bo[buf].modifiable = true
    vim.cmd.startinsert({ bang = true })
  end, opts)

  vim.keymap.set('i', '<CR>', function()
    local line = vim.api.nvim_get_current_line()
    if line and line ~= '' and not line:match('^%s*$') then
      tmux.run(line, false, false)
      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, { '> ' .. line, '' })
      vim.bo[buf].modifiable = false
      vim.cmd.stopinsert()
    end
  end, opts)
end

-- Show all debug windows
function M.show_all()
  M.show_variables()
  vim.defer_fn(M.show_callstack, 10)
  vim.defer_fn(M.show_breakpoints, 20)
  vim.defer_fn(M.show_repl, 30)
end

-- Window show functions map
local WINDOW_SHOW_FUNCS = {
  variables = M.show_variables,
  callstack = M.show_callstack,
  breakpoints = M.show_breakpoints,
  repl = M.show_repl,
}

-- Toggle a specific window
function M.toggle_window(name)
  local win = M.windows[name]
  if win and vim.api.nvim_win_is_valid(win) then
    M.close_window(name)
  else
    local show_fn = WINDOW_SHOW_FUNCS[name]
    if show_fn then
      show_fn()
    else
      utils.notify('Unknown window: ' .. name, vim.log.levels.WARN)
    end
  end
end

-- Create debug control bar
function M.show_control_bar()
  local ok, debug_module = pcall(require, 'matlab.debug')
  if not ok then
    utils.notify('Failed to load debug module.', vim.log.levels.ERROR)
    return
  end

  local is_active = debug_module.debug_active
  local status_icon = is_active and '🔴' or '⚪'
  local status_text = is_active and 'DEBUGGING' or 'STOPPED'

  local content = {
    '╔════════════════════════════════════════════════════════════════════════════╗',
    string.format('║ %s MATLAB Debug Controls - %s%s║',
      status_icon, status_text, string.rep(' ', 55 - #status_text)),
    '╠════════════════════════════════════════════════════════════════════════════╣',
    '║  F-keys work GLOBALLY during debug session (from any buffer)               ║',
    '║                                                                            ║',
    '║  [F5] Continue/Start  [F10] Step Over  [F11] Step Into  [F12] Step Out     ║',
    '║  [Shift+F5] Stop Debug                                                     ║',
    '║                                                                            ║',
    '║  [b] Toggle Breakpoint   [B] Clear All Breakpoints                         ║',
    '║  [s] Start Debug         [q] Stop Debug & Close Bar                        ║',
    '║                                                                            ║',
    '║  [v] Variables  [c] Call Stack  [p] Breakpoints  [r] REPL  [a] Show All    ║',
    '║                                                                            ║',
    '╚════════════════════════════════════════════════════════════════════════════╝',
  }

  local win, buf = M.create_window('controls', 'Debug Controls', content)
  if not win or not buf then
    return
  end

  -- Set keymaps for control bar
  local opts = { buffer = buf, noremap = true, silent = true }

  -- Debug stepping
  vim.keymap.set('n', '<F5>', debug_module.continue_debug, opts)
  vim.keymap.set('n', '<F10>', debug_module.step_over, opts)
  vim.keymap.set('n', '<F11>', debug_module.step_into, opts)
  vim.keymap.set('n', '<F12>', debug_module.step_out, opts)

  -- Breakpoint management
  vim.keymap.set('n', 'b', debug_module.toggle_breakpoint, opts)
  vim.keymap.set('n', 'B', debug_module.clear_breakpoints, opts)

  -- Debug session
  vim.keymap.set('n', 's', debug_module.start_debug, opts)
  vim.keymap.set('n', 'q', function()
    debug_module.stop_debug()
    M.close_window('controls')
  end, opts)

  -- Window management
  vim.keymap.set('n', 'v', M.show_variables, opts)
  vim.keymap.set('n', 'c', M.show_callstack, opts)
  vim.keymap.set('n', 'p', M.show_breakpoints, opts)
  vim.keymap.set('n', 'r', M.show_repl, opts)
  vim.keymap.set('n', 'a', M.show_all, opts)
end

-- Update all open windows with current debug state
function M.update_all()
  for name, win in pairs(M.windows) do
    if vim.api.nvim_win_is_valid(win) then
      local show_fn = WINDOW_SHOW_FUNCS[name]
      if show_fn and name ~= 'repl' then
        show_fn()
      end
    end
  end

  -- Update control bar if it's open
  if M.windows.controls and vim.api.nvim_win_is_valid(M.windows.controls) then
    M.show_control_bar()
  end
end

-- Setup autocmds for UI management
local function setup_autocmds()
  local group = vim.api.nvim_create_augroup('MatlabDebugUI', { clear = true })

  -- Update UI when debug state changes (custom event)
  vim.api.nvim_create_autocmd('User', {
    group = group,
    pattern = 'MatlabDebugStateChanged',
    callback = M.update_all,
  })

  -- Close windows on VimResized to avoid layout issues
  vim.api.nvim_create_autocmd('VimResized', {
    group = group,
    callback = function()
      -- Optionally close windows or let them handle resize
      -- M.close_all()
    end,
  })
end

-- Initialize the UI system
function M.setup()
  M.load_config()
  setup_autocmds()
end

return M
