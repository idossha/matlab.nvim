-- MATLAB Debugging UI - similar to nvim-dap-ui
-- Provides floating windows for debugging information
local M = {}
local tmux = require('matlab.tmux')
local utils = require('matlab.utils')

-- UI state
M.windows = {
  variables = nil,
  callstack = nil,
  breakpoints = nil,
  repl = nil
}

M.buffers = {
  variables = nil,
  callstack = nil,
  breakpoints = nil,
  repl = nil
}

-- Window configuration (will be updated from user config)
M.config = {
  width = 40,
  height = 20,
  variables = { position = 'right', size = 0.3 },
  callstack = { position = 'bottom', size = 0.3 },
  breakpoints = { position = 'left', size = 0.25 },
  repl = { position = 'bottom', size = 0.4 }
}

-- Load configuration from matlab.config
function M.load_config()
  local config = require('matlab.config')
  local ui_config = config.get('debug_ui') or {}

  M.config.variables.position = ui_config.variables_position or M.config.variables.position
  M.config.variables.size = ui_config.variables_size or M.config.variables.size
  M.config.callstack.position = ui_config.callstack_position or M.config.callstack.position
  M.config.callstack.size = ui_config.callstack_size or M.config.callstack.size
  M.config.breakpoints.position = ui_config.breakpoints_position or M.config.breakpoints.position
  M.config.breakpoints.size = ui_config.breakpoints_size or M.config.breakpoints.size
  M.config.repl.position = ui_config.repl_position or M.config.repl.position
  M.config.repl.size = ui_config.repl_size or M.config.repl.size
end

-- Create a floating window
function M.create_window(name, title, content_lines)
  -- Close existing window if it exists
  M.close_window(name)

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  M.buffers[name] = buf

  -- Set buffer content
  if content_lines and #content_lines > 0 then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, content_lines)
  else
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {title, "", "Loading..."})
  end

  -- Set buffer options
  vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_name(buf, 'MATLAB Debug ' .. title)

  -- Calculate window position and size
  local win_config = M.get_window_config(name, title)

  -- Create window
  local win = vim.api.nvim_open_win(buf, false, win_config)
  M.windows[name] = win

  -- Set window options
  vim.api.nvim_win_set_option(win, 'wrap', false)
  vim.api.nvim_win_set_option(win, 'number', false)
  vim.api.nvim_win_set_option(win, 'relativenumber', false)
  vim.api.nvim_win_set_option(win, 'cursorline', true)

  -- Set key mappings for the window
  local keymap_opts = { buffer = buf, noremap = true, silent = true }
  vim.keymap.set('n', 'q', function() M.close_window(name) end, keymap_opts)
  vim.keymap.set('n', '<Esc>', function() M.close_window(name) end, keymap_opts)
  vim.keymap.set('n', '<C-c>', function() M.close_window(name) end, keymap_opts)

  return win, buf
end

-- Get window configuration based on position
function M.get_window_config(name, title)
  local cfg = M.config[name]
  local screen_width = vim.o.columns
  local screen_height = vim.o.lines

  if cfg.position == 'right' then
    return {
      relative = 'editor',
      width = math.floor(screen_width * cfg.size),
      height = screen_height - 4,
      col = screen_width - math.floor(screen_width * cfg.size),
      row = 0,
      style = 'minimal',
      border = 'single',
      title = title,
      title_pos = 'center'
    }
  elseif cfg.position == 'left' then
    return {
      relative = 'editor',
      width = math.floor(screen_width * cfg.size),
      height = screen_height - 4,
      col = 0,
      row = 0,
      style = 'minimal',
      border = 'single',
      title = title,
      title_pos = 'center'
    }
  elseif cfg.position == 'bottom' then
    return {
      relative = 'editor',
      width = screen_width,
      height = math.floor(screen_height * cfg.size),
      col = 0,
      row = screen_height - math.floor(screen_height * cfg.size),
      style = 'minimal',
      border = 'single',
      title = title,
      title_pos = 'center'
    }
  else -- top
    return {
      relative = 'editor',
      width = screen_width,
      height = math.floor(screen_height * cfg.size),
      col = 0,
      row = 0,
      style = 'minimal',
      border = 'single',
      title = title,
      title_pos = 'center'
    }
  end
end

-- Close a specific window
function M.close_window(name)
  if M.windows[name] and vim.api.nvim_win_is_valid(M.windows[name]) then
    vim.api.nvim_win_close(M.windows[name], true)
    M.windows[name] = nil
  end
  if M.buffers[name] and vim.api.nvim_buf_is_valid(M.buffers[name]) then
    vim.api.nvim_buf_delete(M.buffers[name], { force = true })
    M.buffers[name] = nil
  end
end

-- Close all debug windows
function M.close_all()
  for name, _ in pairs(M.windows) do
    M.close_window(name)
  end
end

-- Update a window's content
function M.update_window(name, content_lines)
  if not M.buffers[name] or not vim.api.nvim_buf_is_valid(M.buffers[name]) then
    return
  end

  vim.api.nvim_buf_set_option(M.buffers[name], 'modifiable', true)
  vim.api.nvim_buf_set_lines(M.buffers[name], 0, -1, false, content_lines or {"No data available"})
  vim.api.nvim_buf_set_option(M.buffers[name], 'modifiable', false)
end

-- Show variables window
function M.show_variables()
  local debug_module = require('matlab.debug')
  if not debug_module.is_available() then
    utils.notify('MATLAB pane not available.', vim.log.levels.ERROR)
    return
  end

  -- Get variables from MATLAB workspace
  tmux.run('whos', false, false)

  -- For now, show a placeholder - in a real implementation we'd parse the output
  local content = {
    "MATLAB Variables",
    "================",
    "",
    "Variables in workspace:",
    "(Run 'whos' in MATLAB pane to see current variables)",
    "",
    "Common variables:",
    "- ans: Last result",
    "- All user-defined variables",
    "",
    "Press 'q' to close"
  }

  M.create_window('variables', ' Variables ', content)
end

-- Show call stack window
function M.show_callstack()
  local debug_module = require('matlab.debug')
  if not debug_module.is_available() then
    utils.notify('MATLAB pane not available.', vim.log.levels.ERROR)
    return
  end

  -- Get call stack from MATLAB
  tmux.run('dbstack', false, false)

  local content = {
    "Call Stack",
    "==========",
    "",
    "Current call stack:",
    "(Run 'dbstack' in MATLAB pane to see current stack)",
    "",
    "Stack frames will appear here during debugging",
    "",
    "Press 'q' to close"
  }

  M.create_window('callstack', ' Call Stack ', content)
end

-- Show breakpoints window
function M.show_breakpoints()
  local debug_module = require('matlab.debug')
  local content = {
    "Breakpoints",
    "===========",
    ""
  }

  -- Add current breakpoints
  local has_breakpoints = false
  for bufnr, buf_breakpoints in pairs(debug_module.breakpoints) do
    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t')
    for line, _ in pairs(buf_breakpoints) do
      table.insert(content, string.format("• %s:%d", filename, line))
      has_breakpoints = true
    end
  end

  if not has_breakpoints then
    table.insert(content, "No breakpoints set")
  end

  table.insert(content, "")
  table.insert(content, "Commands:")
  table.insert(content, "- :MatlabDebugToggleBreakpoint - Toggle breakpoint")
  table.insert(content, "- :MatlabDebugClearBreakpoints - Clear all")
  table.insert(content, "")
  table.insert(content, "Press 'q' to close")

  M.create_window('breakpoints', ' Breakpoints ', content)
end

-- Show REPL window
function M.show_repl()
  local debug_module = require('matlab.debug')
  if not debug_module.is_available() then
    utils.notify('MATLAB pane not available.', vim.log.levels.ERROR)
    return
  end

  local content = {
    "MATLAB REPL",
    "===========",
    "",
    "Type MATLAB commands here and press Enter to execute.",
    "Results will appear in the MATLAB pane.",
    "",
    "Available during debugging:",
    "- Any MATLAB expression",
    "- whos - Show variables",
    "- dbstack - Show call stack",
    "- dbcont - Continue execution",
    "- dbstep - Step through code",
    "",
    "Press 'q' to close, 'i' to enter insert mode"
  }

  local win, buf = M.create_window('repl', ' MATLAB REPL ', content)

  -- Special key mappings for REPL
  local keymap_opts = { buffer = buf, noremap = true, silent = true }
  vim.keymap.set('n', 'i', function()
    vim.api.nvim_buf_set_option(buf, 'modifiable', true)
    vim.cmd('startinsert')
  end, keymap_opts)

  vim.keymap.set('i', '<CR>', function()
    -- Get current line and execute it as MATLAB command
    local line = vim.api.nvim_get_current_line()
    if line and line ~= "" then
      tmux.run(line, false, false)
      -- Add the command to the buffer
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, {"", "> " .. line})
    end
  end, keymap_opts)
end

-- Show all debug windows
function M.show_all()
  M.show_variables()
  M.show_callstack()
  M.show_breakpoints()
  M.show_repl()
end

-- Toggle a specific window
function M.toggle_window(name)
  if M.windows[name] and vim.api.nvim_win_is_valid(M.windows[name]) then
    M.close_window(name)
  else
    if name == 'variables' then
      M.show_variables()
    elseif name == 'callstack' then
      M.show_callstack()
    elseif name == 'breakpoints' then
      M.show_breakpoints()
    elseif name == 'repl' then
      M.show_repl()
    end
  end
end

-- Update all windows with current debug state
function M.update_all()
  if M.windows.variables then
    M.show_variables() -- This will refresh the variables window
  end
  if M.windows.callstack then
    M.show_callstack() -- This will refresh the call stack window
  end
  if M.windows.breakpoints then
    M.show_breakpoints() -- This will refresh the breakpoints window
  end
  -- REPL window doesn't need updating as it's interactive
end

-- Setup autocmds for UI management
function M.setup_autocmds()
  -- Close all windows when leaving MATLAB files
  vim.api.nvim_create_augroup('matlab_debug_ui', { clear = true })

  vim.api.nvim_create_autocmd('BufLeave', {
    group = 'matlab_debug_ui',
    pattern = '*.m',
    callback = function()
      -- Optional: close windows when leaving MATLAB files
      -- M.close_all()
    end
  })

  -- Update UI when debug state changes
  vim.api.nvim_create_autocmd('User', {
    group = 'matlab_debug_ui',
    pattern = 'MatlabDebugStateChanged',
    callback = function()
      M.update_all()
    end
  })
end

-- Initialize the UI system
function M.setup()
  M.load_config()
  M.setup_autocmds()
  utils.notify('MATLAB Debug UI system initialized.', vim.log.levels.INFO)
end

return M
