-- Debugging functionality for matlab.nvim
-- Provides debugging capabilities using MATLAB's built-in debugging commands
local M = {}
local tmux = require('matlab.tmux')
local utils = require('matlab.utils')
local config = require('matlab.config')

-- Debug session state
M.debug_active = false
M.current_file = nil
M.current_line = nil
M.breakpoints = {}

-- UI state
M.debug_signs_defined = false
M.debug_highlight_ns = nil
M.sign_group = 'matlab_debug'

-- Lazy-load debug_ui to avoid circular dependency
local debug_ui
local function get_debug_ui()
  if not debug_ui then
    debug_ui = require('matlab.debug_ui')
  end
  return debug_ui
end

-- Helper: validate debug prerequisites
local function validate_debug_context(require_active)
  if not tmux.exists() then
    utils.notify('MATLAB pane not available.', vim.log.levels.ERROR)
    return false
  end

  if require_active and not M.debug_active then
    utils.notify('No active debugging session.', vim.log.levels.ERROR)
    return false
  end

  return true
end

-- Helper: validate MATLAB file context
local function validate_matlab_file()
  if vim.bo.filetype ~= 'matlab' then
    utils.notify('This operation requires a MATLAB file.', vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Check if debugging is available
function M.is_available()
  return tmux.exists()
end

-- Start debugging session
function M.start_debug()
  if not validate_debug_context(false) or not validate_matlab_file() then
    return
  end

  -- Save file if modified
  if vim.bo.modified then
    local ok, err = pcall(vim.cmd.write)
    if not ok then
      utils.notify('Failed to save file: ' .. tostring(err), vim.log.levels.ERROR)
      return
    end
  end

  -- Get current file info
  local filename = vim.fn.expand('%:t:r')
  if filename == '' then
    utils.notify('Cannot determine filename.', vim.log.levels.ERROR)
    return
  end

  M.current_file = filename

  -- Clear any existing debug state
  tmux.run('dbclear all', false, false)
  tmux.run('dbquit', false, false)

  -- Set breakpoints that were previously set
  M.restore_breakpoints()

  -- Start debugging the current file
  local cmd = string.format('dbstop in %s at 1', filename)
  tmux.run(cmd, false, false)

  M.debug_active = true
  utils.notify('Debug session started: ' .. filename, vim.log.levels.INFO)
end

-- Stop debugging session
function M.stop_debug()
  if not M.debug_active then
    return
  end

  if tmux.exists() then
    tmux.run('dbquit', false, false)
  end

  M.debug_active = false
  M.current_file = nil
  M.current_line = nil
  M.clear_debug_signs()
  utils.notify('Debug session stopped.', vim.log.levels.INFO)
end

-- Helper: execute debug command
local function exec_debug_cmd(cmd, msg)
  if not validate_debug_context(true) then
    return false
  end

  tmux.run(cmd, false, false)
  if msg then
    utils.notify(msg, vim.log.levels.INFO)
  end
  return true
end

-- Continue execution
function M.continue_debug()
  exec_debug_cmd('dbcont', 'Continuing execution...')
end

-- Step over (next line)
function M.step_over()
  exec_debug_cmd('dbstep', 'Stepping over...')
end

-- Step into function
function M.step_into()
  exec_debug_cmd('dbstep in', 'Stepping into...')
end

-- Step out of function
function M.step_out()
  exec_debug_cmd('dbstep out', 'Stepping out...')
end

-- Helper: update breakpoint sign
local function update_breakpoint_sign(bufnr, line, action)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if action == 'set' then
    vim.fn.sign_place(0, M.sign_group, 'matlab_breakpoint', bufnr, { lnum = line, priority = 10 })
  elseif action == 'clear' then
    vim.fn.sign_unplace(M.sign_group, { buffer = bufnr, id = line })
  end
end

-- Toggle breakpoint at current line
function M.toggle_breakpoint()
  if not validate_debug_context(false) or not validate_matlab_file() then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local filename = vim.fn.expand('%:t:r')
  local line = vim.fn.line('.')

  if filename == '' then
    utils.notify('Cannot determine filename.', vim.log.levels.ERROR)
    return
  end

  -- Initialize breakpoints table for this buffer
  M.breakpoints[bufnr] = M.breakpoints[bufnr] or {}

  if M.breakpoints[bufnr][line] then
    -- Remove breakpoint
    local cmd = string.format('dbclear %s at %d', filename, line)
    tmux.run(cmd, false, false)
    M.breakpoints[bufnr][line] = nil
    update_breakpoint_sign(bufnr, line, 'clear')
    utils.notify('Breakpoint cleared: line ' .. line, vim.log.levels.INFO)
  else
    -- Add breakpoint
    local cmd = string.format('dbstop in %s at %d', filename, line)
    tmux.run(cmd, false, false)
    M.breakpoints[bufnr][line] = true
    update_breakpoint_sign(bufnr, line, 'set')
    utils.notify('Breakpoint set: line ' .. line, vim.log.levels.INFO)
  end
end

-- Clear all breakpoints
function M.clear_breakpoints()
  if not validate_debug_context(false) then
    return
  end

  tmux.run('dbclear all', false, false)

  -- Clear all signs
  for bufnr, _ in pairs(M.breakpoints) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.fn.sign_unplace(M.sign_group, { buffer = bufnr })
    end
  end

  M.breakpoints = {}
  utils.notify('All breakpoints cleared.', vim.log.levels.INFO)
end

-- UI delegation helpers (simplified)
function M.show_debug_ui()
  if not validate_debug_context(false) then
    return
  end
  get_debug_ui().show_all()
end

function M.show_variables()
  get_debug_ui().show_variables()
end

function M.show_callstack()
  get_debug_ui().show_callstack()
end

function M.show_breakpoints()
  get_debug_ui().show_breakpoints()
end

function M.show_repl()
  get_debug_ui().show_repl()
end

function M.toggle_variables()
  get_debug_ui().toggle_window('variables')
end

function M.toggle_callstack()
  get_debug_ui().toggle_window('callstack')
end

function M.toggle_breakpoints()
  get_debug_ui().toggle_window('breakpoints')
end

function M.toggle_repl()
  get_debug_ui().toggle_window('repl')
end

function M.close_ui()
  get_debug_ui().close_all()
end

-- Restore breakpoints from internal storage
function M.restore_breakpoints()
  if not tmux.exists() then
    return
  end

  for bufnr, buf_breakpoints in pairs(M.breakpoints) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t:r')
      if filename ~= '' then
        for line, _ in pairs(buf_breakpoints) do
          local cmd = string.format('dbstop in %s at %d', filename, line)
          tmux.run(cmd, false, false)
          update_breakpoint_sign(bufnr, line, 'set')
        end
      end
    end
  end
end

-- Get debug status string for statusline
function M.get_status_string()
  if not M.debug_active then
    return ''
  end

  local parts = { 'DEBUG' }
  if M.current_file then
    table.insert(parts, M.current_file)
    if M.current_line then
      table.insert(parts, ':' .. M.current_line)
    end
  end

  return table.concat(parts, ' ')
end

-- Get current debug status
function M.get_debug_status()
  return M.debug_active and 'active' or 'inactive'
end

-- Clear debug signs from all buffers
function M.clear_debug_signs()
  vim.fn.sign_unplace(M.sign_group)
end

-- Setup debug UI elements (signs and highlights)
function M.setup_debug_ui()
  if M.debug_signs_defined then
    return
  end

  -- Define debug signs with modern highlight groups
  vim.fn.sign_define('matlab_debug_current', {
    text = '▶',
    texthl = 'DiagnosticSignInfo',
    linehl = 'CursorLine',
    numhl = 'DiagnosticSignInfo'
  })

  -- Create namespace for debug highlights
  M.debug_highlight_ns = vim.api.nvim_create_namespace('matlab_debug')

  M.debug_signs_defined = true
end

-- Setup autocmds for cleanup
local function setup_autocmds()
  local group = vim.api.nvim_create_augroup('MatlabDebug', { clear = true })

  -- Clean up breakpoints when buffer is deleted
  vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    pattern = '*.m',
    callback = function(args)
      local bufnr = args.buf
      if M.breakpoints[bufnr] then
        M.breakpoints[bufnr] = nil
      end
    end,
  })

  -- Stop debug session on VimLeavePre
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    callback = function()
      if M.debug_active then
        M.stop_debug()
      end
    end,
  })
end

-- Initialize debugging module
function M.setup()
  M.setup_debug_ui()
  setup_autocmds()
  get_debug_ui().setup()
end

return M
