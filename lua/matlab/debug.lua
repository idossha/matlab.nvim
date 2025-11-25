-- Debugging functionality for matlab.nvim
-- Provides debugging capabilities using MATLAB's built-in debugging commands
local M = {}
local tmux = require('matlab.tmux')
local utils = require('matlab.utils')
local config = require('matlab.config')
local debug_ui = require('matlab.debug_ui')

-- Debug session state
M.debug_active = false
M.current_file = nil
M.current_line = nil
M.breakpoints = {}

-- UI state
M.debug_signs_defined = false
M.debug_highlight_ns = nil

-- Check if debugging is available
function M.is_available()
  return tmux.exists()
end

-- Start debugging session
function M.start_debug()
  if not M.is_available() then
    utils.notify('Cannot start debugging: MATLAB pane not available.', vim.log.levels.ERROR)
    return
  end

  -- Check if we're in a MATLAB file
  local filetype = vim.bo.filetype
  if filetype ~= 'matlab' then
    utils.notify('Debugging can only be started in MATLAB files.', vim.log.levels.ERROR)
    return
  end

  -- Save file if modified
  if vim.bo.modified then
    vim.cmd('write')
  end

  -- Get current file info
  local filename = vim.fn.expand('%:t:r')
  M.current_file = filename

  -- Clear any existing debug state
  tmux.run('dbclear all', false, false)
  tmux.run('dbquit', false, false)

  -- Set breakpoints that were previously set
  M.restore_breakpoints()

  -- Start debugging the current file
  local cmd = string.format('dbstop %s', filename)
  tmux.run(cmd, false, false)

  M.debug_active = true
  utils.notify('MATLAB debugging session started for ' .. filename, vim.log.levels.INFO)
end

-- Stop debugging session
function M.stop_debug()
  if not M.debug_active then
    return
  end

  if M.is_available() then
    tmux.run('dbquit', false, false)
  end

  M.debug_active = false
  M.current_file = nil
  M.current_line = nil
  utils.notify('MATLAB debugging session stopped.', vim.log.levels.INFO)
end

-- Continue execution
function M.continue_debug()
  if not M.debug_active then
    utils.notify('No active debugging session.', vim.log.levels.ERROR)
    return
  end

  if not M.is_available() then
    utils.notify('MATLAB pane not available.', vim.log.levels.ERROR)
    return
  end

  tmux.run('dbcont', false, false)
  utils.notify('Continuing execution...', vim.log.levels.INFO)
end

-- Step over (next line)
function M.step_over()
  if not M.debug_active then
    utils.notify('No active debugging session.', vim.log.levels.ERROR)
    return
  end

  if not M.is_available() then
    utils.notify('MATLAB pane not available.', vim.log.levels.ERROR)
    return
  end

  tmux.run('dbstep', false, false)
  utils.notify('Stepped over.', vim.log.levels.INFO)
end

-- Step into function
function M.step_into()
  if not M.debug_active then
    utils.notify('No active debugging session.', vim.log.levels.ERROR)
    return
  end

  if not M.is_available() then
    utils.notify('MATLAB pane not available.', vim.log.levels.ERROR)
    return
  end

  tmux.run('dbstep in', false, false)
  utils.notify('Stepped into function.', vim.log.levels.INFO)
end

-- Step out of function
function M.step_out()
  if not M.debug_active then
    utils.notify('No active debugging session.', vim.log.levels.ERROR)
    return
  end

  if not M.is_available() then
    utils.notify('MATLAB pane not available.', vim.log.levels.ERROR)
    return
  end

  tmux.run('dbstep out', false, false)
  utils.notify('Stepped out of function.', vim.log.levels.INFO)
end

-- Toggle breakpoint at current line
function M.toggle_breakpoint()
  local filetype = vim.bo.filetype
  if filetype ~= 'matlab' then
    utils.notify('Breakpoints can only be set in MATLAB files.', vim.log.levels.ERROR)
    return
  end

  if not M.is_available() then
    utils.notify('MATLAB pane not available.', vim.log.levels.ERROR)
    return
  end

  local filename = vim.fn.expand('%:t:r')
  local line = vim.fn.line('.')

  -- Check if breakpoint already exists
  local bufnr = vim.api.nvim_get_current_buf()
  if not M.breakpoints[bufnr] then
    M.breakpoints[bufnr] = {}
  end

  if M.breakpoints[bufnr][line] then
    -- Remove breakpoint
    local cmd = string.format('dbclear %s at %d', filename, line)
    tmux.run(cmd, false, false)
    M.breakpoints[bufnr][line] = nil
    utils.notify('Breakpoint cleared at line ' .. line, vim.log.levels.INFO)
  else
    -- Add breakpoint
    local cmd = string.format('dbstop %s at %d', filename, line)
    tmux.run(cmd, false, false)
    M.breakpoints[bufnr][line] = true
    utils.notify('Breakpoint set at line ' .. line, vim.log.levels.INFO)
  end
end

-- Clear all breakpoints
function M.clear_breakpoints()
  if not M.is_available() then
    utils.notify('MATLAB pane not available.', vim.log.levels.ERROR)
    return
  end

  tmux.run('dbclear all', false, false)
  M.breakpoints = {}
  utils.notify('All breakpoints cleared.', vim.log.levels.INFO)
end

-- Show debug UI (variables, call stack, etc.)
function M.show_debug_ui()
  if not M.is_available() then
    utils.notify('MATLAB pane not available.', vim.log.levels.ERROR)
    return
  end

  debug_ui.show_all()
end

-- Show individual UI windows
function M.show_variables()
  debug_ui.show_variables()
end

function M.show_callstack()
  debug_ui.show_callstack()
end

function M.show_breakpoints()
  debug_ui.show_breakpoints()
end

function M.show_repl()
  debug_ui.show_repl()
end

-- Toggle UI windows
function M.toggle_variables()
  debug_ui.toggle_window('variables')
end

function M.toggle_callstack()
  debug_ui.toggle_window('callstack')
end

function M.toggle_breakpoints()
  debug_ui.toggle_window('breakpoints')
end

function M.toggle_repl()
  debug_ui.toggle_window('repl')
end

-- Close all UI windows
function M.close_ui()
  debug_ui.close_all()
end

-- Restore breakpoints from our internal storage
function M.restore_breakpoints()
  if not M.is_available() then
    return
  end

  for bufnr, buf_breakpoints in pairs(M.breakpoints) do
    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t:r')
    for line, _ in pairs(buf_breakpoints) do
      local cmd = string.format('dbstop %s at %d', filename, line)
      tmux.run(cmd, false, false)
    end
  end
end

-- Update current debug line from MATLAB output
function M.update_current_line()
  if not M.debug_active or not M.is_available() then
    return
  end

  -- Get current debug stack to find current line
  -- MATLAB's dbstack command shows the current execution point
  tmux.run('dbstack', false, false)

  -- Note: In a real implementation, we would need to parse the output
  -- of dbstack to get the current file and line. For now, we'll rely
  -- on the user to navigate to the correct file and line manually.
end

-- Get debug status string for status line
function M.get_status_string()
  if not M.debug_active then
    return ''
  end

  local status = 'MATLAB[DEBUG]'
  if M.current_file then
    status = status .. ' ' .. M.current_file
    if M.current_line then
      status = status .. ':' .. M.current_line
    end
  end

  return status
end

-- Get current debug status
function M.get_debug_status()
  if not M.debug_active then
    return 'inactive'
  end

  return 'active'
end

-- Setup debug UI elements (signs and highlights)
function M.setup_debug_ui()
  if M.debug_signs_defined then
    return
  end

  -- Define debug signs
  vim.fn.sign_define('matlab_debug_current', {
    text = '▶',
    texthl = 'MatlabDebugCurrent',
    linehl = 'MatlabDebugCurrentLine',
    numhl = 'MatlabDebugCurrent'
  })

  -- Create highlight groups for debug UI
  vim.api.nvim_command('highlight default MatlabDebugCurrent guifg=#00ff00 guibg=#004400 ctermfg=46 ctermbg=22 gui=bold cterm=bold')
  vim.api.nvim_command('highlight default MatlabDebugCurrentLine guibg=#002200 ctermbg=235')

  -- Create namespace for debug highlights
  M.debug_highlight_ns = vim.api.nvim_create_namespace('matlab_debug')

  M.debug_signs_defined = true
end

-- Update debug UI to show current execution line
function M.update_debug_ui()
  -- Clear existing debug signs
  vim.fn.sign_unplace('matlab_debug')

  if M.debug_active and M.current_line then
    -- Get current buffer
    local bufnr = vim.api.nvim_get_current_buf()
    local filename = vim.fn.expand('%:t:r')

    -- Only show debug indicator if we're in the file being debugged
    if filename == M.current_file then
      vim.fn.sign_place(0, 'matlab_debug', 'matlab_debug_current', bufnr, {lnum = M.current_line})
    end
  end
end

-- Initialize debugging module
function M.setup()
  M.setup_debug_ui()
  debug_ui.setup()
  utils.notify('MATLAB debugging module initialized.', vim.log.levels.INFO)
end

return M
