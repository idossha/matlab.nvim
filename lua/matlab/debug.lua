-- Simple MATLAB Debugging Module
-- Uses only MATLAB's native debugging commands (dbstop, dbcont, dbstep, etc.)
-- No external dependencies required

local M = {}
local tmux = require('matlab.tmux')
local utils = require('matlab.utils')

-- Debug state
M.debug_active = false
M.current_file = nil
M.current_line = nil
M.current_bufnr = nil
M.breakpoints = {}  -- { [bufnr] = { [line] = boolean } }

-- Sign configuration
M.sign_group = 'matlab_debug'
M.signs_defined = false

-- Helper: validate prerequisites
local function validate_context(require_active)
  if not tmux.exists() then
    utils.notify('MATLAB pane not available. Start with :MatlabStartServer', vim.log.levels.ERROR)
    return false
  end

  if require_active and not M.debug_active then
    utils.notify('No active debug session. Start with :MatlabDebugStart', vim.log.levels.ERROR)
    return false
  end

  return true
end

-- Helper: validate MATLAB file
local function is_matlab_file()
  if vim.bo.filetype ~= 'matlab' then
    utils.notify('Must be in a MATLAB file', vim.log.levels.ERROR)
    return false
  end
  return true
end

-- Helper: clear current debug line sign
local function clear_debug_line_sign()
  if M.current_bufnr and M.current_line then
    vim.fn.sign_unplace(M.sign_group, {
      buffer = M.current_bufnr,
      id = 999999  -- Use specific ID for debug line
    })
  end
end

-- Helper: update current debug line sign
local function update_debug_line_sign(bufnr, line)
  -- Clear previous debug line
  clear_debug_line_sign()

  -- Set new debug line
  if bufnr and line and vim.api.nvim_buf_is_valid(bufnr) then
    M.current_bufnr = bufnr
    M.current_line = line

    vim.fn.sign_place(999999, M.sign_group, 'matlab_debug_line', bufnr, {
      lnum = line,
      priority = 20  -- Higher priority than breakpoints
    })

    -- Move cursor to the debug line
    local wins = vim.fn.win_findbuf(bufnr)
    if #wins > 0 then
      vim.api.nvim_win_set_cursor(wins[1], {line, 0})
    end
  end
end

-- Helper: parse dbstack output and update current line
local function parse_and_update_location()
  if not M.debug_active then
    return
  end

  -- Get the tmux pane content to parse dbstack output
  local pane = tmux.get_server_pane()
  if not pane then
    return
  end

  -- Capture recent output from MATLAB pane (more lines to be safe)
  local output = tmux.execute('capture-pane -t ' .. vim.fn.shellescape(pane) .. ' -p -S -200')

  if not output then
    return
  end

  -- Parse dbstack output for current file and line
  -- Try multiple patterns to be more robust:
  -- Pattern 1: "> In <filename> (line <number>)"
  -- Pattern 2: "In <filename> (line <number>)" at the top of stack
  -- Pattern 3: "K>> " prompt followed by file info

  local filename, line

  -- Try pattern with ">" indicator (most recent stack frame)
  filename, line = output:match('> In ([^%(]+)%(line (%d+)%)')

  -- If not found, try to find the first "In ... (line ...)" after K>> prompt
  if not filename then
    -- Look for the dbstack output - usually appears after K>>
    local stack_section = output:match('K>>.-\n(.-)\n[^\n]*K>>')
    if stack_section then
      filename, line = stack_section:match('In ([^%(]+)%(line (%d+)%)')
    end
  end

  -- Last resort: find any "In ... (line ...)" pattern
  if not filename then
    filename, line = output:match('In ([^%(]+)%(line (%d+)%)')
  end

  if filename and line then
    -- Clean up filename (remove extra spaces and path separators)
    filename = vim.trim(filename)
    filename = filename:gsub('^.*[/\\]', '')  -- Remove path if present
    filename = filename:gsub('%.m$', '')      -- Remove .m extension if present
    line = tonumber(line)

    utils.log('Parsed debug location: ' .. filename .. ':' .. line, 'DEBUG')

    -- Find buffer with matching filename
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        local buf_filename = vim.fn.fnamemodify(bufname, ':t:r')

        if buf_filename == filename then
          update_debug_line_sign(bufnr, line)
          utils.log('Updated debug line sign at ' .. filename .. ':' .. line, 'DEBUG')
          return
        end
      end
    end
    utils.log('Could not find buffer for ' .. filename, 'DEBUG')
  else
    utils.log('Could not parse debug location from output', 'DEBUG')
  end
end

-- Helper: get current debug location and move cursor
local function move_to_debug_location()
  if not validate_context(true) then
    return
  end

  -- Use dbstack to show current location in MATLAB pane
  tmux.run('dbstack', true, false)

  -- Wait for MATLAB to output, then parse multiple times to ensure we catch it
  vim.defer_fn(parse_and_update_location, 300)
  vim.defer_fn(parse_and_update_location, 600)  -- Try again in case first attempt was too early
end

-- Helper: update breakpoint sign
local function update_sign(bufnr, line, action)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  if action == 'set' then
    vim.fn.sign_place(0, M.sign_group, 'matlab_breakpoint', bufnr, {
      lnum = line,
      priority = 10
    })
  elseif action == 'clear' then
    vim.fn.sign_unplace(M.sign_group, { buffer = bufnr, lnum = line })
  end
end

-- Setup signs
function M.setup_signs()
  if M.signs_defined then
    return
  end

  vim.fn.sign_define('matlab_breakpoint', {
    text = '●',
    texthl = 'DiagnosticError',
    linehl = 'DiffDelete',  -- Full line red highlighting
    numhl = 'DiagnosticError'
  })

  vim.fn.sign_define('matlab_debug_line', {
    text = '▶',
    texthl = 'DiagnosticInfo',
    linehl = 'DiffText',  -- Full line blue/cyan highlighting for current position
    numhl = 'DiagnosticInfo'
  })

  M.signs_defined = true
end

-- Start debugging session
function M.start_debug()
  if not validate_context(false) or not is_matlab_file() then
    return
  end

  -- Save file if modified
  if vim.bo.modified then
    local ok = pcall(vim.cmd.write)
    if not ok then
      utils.notify('Failed to save file', vim.log.levels.ERROR)
      return
    end
  end

  -- Get filename and directory
  local filename = vim.fn.expand('%:t:r')
  local filepath = vim.fn.expand('%:p:h')
  if filename == '' then
    utils.notify('Cannot determine filename', vim.log.levels.ERROR)
    return
  end

  M.current_file = filename

  -- Change to file's directory in MATLAB
  local cd_cmd = string.format("cd '%s'", filepath)
  tmux.run(cd_cmd, false, false)

  -- Clear existing debug state in MATLAB
  tmux.run('dbclear all', false, false)
  tmux.run('dbquit', false, false)

  -- Restore breakpoints
  M.restore_breakpoints()

  -- Run the file (will stop at first breakpoint)
  -- Use dbstop at 1 to ensure we enter debug mode at the first line if no breakpoints
  -- This ensures proper debug context for the entire execution
  local has_breakpoints = false
  for _, buf_breakpoints in pairs(M.breakpoints) do
    if next(buf_breakpoints) ~= nil then
      has_breakpoints = true
      break
    end
  end

  if has_breakpoints then
    -- Run normally - will stop at first breakpoint
    tmux.run(filename, false, false)
  else
    -- No breakpoints - set temporary breakpoint at line 1 to enter debug mode
    tmux.run(string.format('dbstop in %s at 1', filename), false, false)
    tmux.run(filename, false, false)
  end

  M.debug_active = true
  utils.notify('Debug started: ' .. filename, vim.log.levels.INFO)

  -- Update current line indicator after starting
  vim.defer_fn(move_to_debug_location, 800)
end

-- Stop debugging
function M.stop_debug()
  if not M.debug_active then
    return
  end

  if tmux.exists() then
    tmux.run('dbquit', false, false)
  end

  -- Clear debug line sign
  clear_debug_line_sign()

  M.debug_active = false
  M.current_file = nil
  M.current_line = nil
  M.current_bufnr = nil
  utils.notify('Debug stopped', vim.log.levels.INFO)
end

-- Helper: update debug UI if available
local function update_debug_ui()
  local ok, debug_ui = pcall(require, 'matlab.debug_ui')
  if ok and debug_ui then
    vim.defer_fn(debug_ui.update_all, 100)
  end
end

-- Continue execution (dbcont)
function M.continue_debug()
  if not validate_context(true) then
    return
  end

  -- Continue execution
  -- IMPORTANT: Use skip_interrupt=true to avoid sending Ctrl+C before dbcont
  -- Sending Ctrl+C interrupts the debug session and can cause errors
  tmux.run('dbcont', true, false)
  utils.notify('Continuing...', vim.log.levels.INFO)

  -- Schedule cursor movement to breakpoint location after a short delay
  vim.defer_fn(move_to_debug_location, 500)

  -- Update debug UI windows
  vim.defer_fn(update_debug_ui, 600)
end

-- Step over (dbstep)
function M.step_over()
  if not validate_context(true) then
    return
  end

  -- Use skip_interrupt=true to avoid interrupting the debug session
  tmux.run('dbstep', true, false)

  -- Schedule cursor movement after stepping
  vim.defer_fn(move_to_debug_location, 300)

  -- Update debug UI windows
  vim.defer_fn(update_debug_ui, 400)
end

-- Step into (dbstep in)
function M.step_into()
  if not validate_context(true) then
    return
  end

  -- Use skip_interrupt=true to avoid interrupting the debug session
  tmux.run('dbstep in', true, false)

  -- Schedule cursor movement after stepping
  vim.defer_fn(move_to_debug_location, 300)

  -- Update debug UI windows
  vim.defer_fn(update_debug_ui, 400)
end

-- Step out (dbstep out)
function M.step_out()
  if not validate_context(true) then
    return
  end

  -- Use skip_interrupt=true to avoid interrupting the debug session
  tmux.run('dbstep out', true, false)

  -- Schedule cursor movement after stepping
  vim.defer_fn(move_to_debug_location, 300)

  -- Update debug UI windows
  vim.defer_fn(update_debug_ui, 400)
end

-- Toggle breakpoint
function M.toggle_breakpoint()
  if not validate_context(false) or not is_matlab_file() then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local filename = vim.fn.expand('%:t:r')
  local line = vim.fn.line('.')

  if filename == '' then
    utils.notify('Cannot determine filename', vim.log.levels.ERROR)
    return
  end

  -- Initialize breakpoints for this buffer
  M.breakpoints[bufnr] = M.breakpoints[bufnr] or {}

  if M.breakpoints[bufnr][line] then
    -- Clear breakpoint
    tmux.run(string.format('dbclear %s at %d', filename, line), false, false)
    M.breakpoints[bufnr][line] = nil
    update_sign(bufnr, line, 'clear')
    utils.notify('Breakpoint cleared: line ' .. line, vim.log.levels.INFO)
  else
    -- Set breakpoint
    tmux.run(string.format('dbstop in %s at %d', filename, line), false, false)
    M.breakpoints[bufnr][line] = true
    update_sign(bufnr, line, 'set')
    utils.notify('Breakpoint set: line ' .. line, vim.log.levels.INFO)
  end
end


-- Clear all breakpoints
function M.clear_breakpoints()
  if not validate_context(false) then
    return
  end

  tmux.run('dbclear all', false, false)

  -- Clear signs
  for bufnr, _ in pairs(M.breakpoints) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.fn.sign_unplace(M.sign_group, { buffer = bufnr })
    end
  end

  M.breakpoints = {}
  utils.notify('All breakpoints cleared', vim.log.levels.INFO)
end


-- Restore breakpoints after starting debug
function M.restore_breakpoints()
  if not tmux.exists() then
    return
  end

  for bufnr, buf_breakpoints in pairs(M.breakpoints) do
    if vim.api.nvim_buf_is_valid(bufnr) then
      local filepath = vim.api.nvim_buf_get_name(bufnr)
      local filename = vim.fn.fnamemodify(filepath, ':t:r')

      if filename ~= '' then
        for line, _ in pairs(buf_breakpoints) do
          tmux.run(string.format('dbstop in %s at %d', filename, line), false, false)
          update_sign(bufnr, line, 'set')
        end
      end
    end
  end
end

-- Show workspace variables (whos)
function M.show_variables()
  if not validate_context(false) then
    return
  end

  tmux.run('whos', false, false)
  utils.notify('Check MATLAB pane for variables', vim.log.levels.INFO)
end

-- Show call stack (dbstack)
function M.show_stack()
  if not validate_context(false) then
    return
  end

  tmux.run('dbstack', false, false)
  utils.notify('Check MATLAB pane for call stack', vim.log.levels.INFO)
end

-- Show breakpoints (dbstatus)
function M.show_breakpoints()
  if not validate_context(false) then
    return
  end

  tmux.run('dbstatus', false, false)
  utils.notify('Check MATLAB pane for breakpoints', vim.log.levels.INFO)
end

-- Evaluate expression
function M.eval_expression()
  if not validate_context(false) then
    return
  end

  local expr = vim.fn.input('Evaluate: ')
  if expr ~= '' then
    -- Use non-shell-escaped version for expressions with special characters
    local use_shell_escape = not string.find(expr, '[><=]')
    tmux.run(expr, false, false, use_shell_escape)
  end
end

-- Get status string for statusline
function M.get_status()
  if not M.debug_active then
    return ''
  end

  return 'DEBUG: ' .. (M.current_file or '')
end

-- Setup autocmds
local function setup_autocmds()
  local group = vim.api.nvim_create_augroup('MatlabDebug', { clear = true })

  -- Clean up on buffer delete
  vim.api.nvim_create_autocmd('BufDelete', {
    group = group,
    pattern = '*.m',
    callback = function(args)
      if M.breakpoints[args.buf] then
        M.breakpoints[args.buf] = nil
      end
    end,
  })

  -- Stop debug on exit
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    callback = function()
      if M.debug_active then
        M.stop_debug()
      end
    end,
  })
end

-- Initialize module
function M.setup()
  M.setup_signs()
  setup_autocmds()
end

return M
