-- Simple MATLAB Debugging Module
-- Uses only MATLAB's native debugging commands (dbstop, dbcont, dbstep, etc.)
-- No external dependencies required

local M = {}
local tmux = require('matlab.tmux')
local utils = require('matlab.utils')

-- Debug state
M.debug_active = false
M.current_file = nil
M.breakpoints = {}  -- { [bufnr] = { [line] = true } }

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

-- Helper: get current debug location and move cursor
local function move_to_debug_location()
  if not validate_context(true) then
    return
  end

  -- Capture dbstack output to get current location
  local output = tmux.run_and_capture('dbstack', true)

  if output then
    -- Parse dbstack output to find current location
    -- dbstack output typically looks like:
    -- > In function_name (file.m) at line 42
    -- We want to extract file.m and line 42

    for line in output:gmatch("[^\r\n]+") do
      -- Look for lines containing "at line" (current location)
      local file, line_num = line:match("In%s+[^%s]+%s*%(([^%)]+)%)%s*at%s+line%s+(%d+)")
      if file and line_num then
        line_num = tonumber(line_num)

        -- Find or open the file
        local bufnr = vim.fn.bufnr(file)
        if bufnr == -1 then
          -- File not open, try to find it
          local full_path = vim.fn.findfile(file, vim.fn.getcwd() .. '/**')
          if full_path ~= '' then
            vim.cmd('edit ' .. vim.fn.fnameescape(full_path))
            bufnr = vim.fn.bufnr(full_path)
          else
            utils.notify('Could not find file: ' .. file, vim.log.levels.WARN)
            return
          end
        else
          -- File already open, switch to it
          vim.cmd('buffer ' .. bufnr)
        end

        -- Move cursor to the line
        vim.api.nvim_win_set_cursor(0, {line_num, 0})

        -- Center the line in the window
        vim.cmd('normal! zz')

        utils.log('Moved cursor to ' .. file .. ':' .. line_num, 'INFO')
        return
      end
    end

    -- If we couldn't parse the output, just show it in the pane
    tmux.run('dbstack', false, false)
    utils.notify('Could not parse debug location, check MATLAB pane', vim.log.levels.WARN)
  else
    -- Fallback: just show in pane
    tmux.run('dbstack', false, false)
    utils.notify('Check MATLAB pane for current location', vim.log.levels.INFO)
  end
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
    linehl = '',
    numhl = ''
  })

  vim.fn.sign_define('matlab_debug_line', {
    text = '▶',
    texthl = 'DiagnosticInfo',
    linehl = 'CursorLine',
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

  -- Run the file (will stop at first breakpoint or line 1)
  tmux.run(filename, false, false)

  M.debug_active = true
  utils.notify('Debug started: ' .. filename, vim.log.levels.INFO)
end

-- Stop debugging
function M.stop_debug()
  if not M.debug_active then
    return
  end

  if tmux.exists() then
    tmux.run('dbquit', false, false)
  end

  M.debug_active = false
  M.current_file = nil
  utils.notify('Debug stopped', vim.log.levels.INFO)
end

-- Continue execution (dbcont)
function M.continue_debug()
  if not validate_context(true) then
    return
  end

  tmux.run('dbcont', false, false)
  utils.notify('Continuing...', vim.log.levels.INFO)

  -- Schedule cursor movement to breakpoint location after a short delay
  vim.defer_fn(move_to_debug_location, 500)
end

-- Step over (dbstep)
function M.step_over()
  if not validate_context(true) then
    return
  end

  tmux.run('dbstep', false, false)

  -- Schedule cursor movement after stepping
  vim.defer_fn(move_to_debug_location, 300)
end

-- Step into (dbstep in)
function M.step_into()
  if not validate_context(true) then
    return
  end

  tmux.run('dbstep in', false, false)

  -- Schedule cursor movement after stepping
  vim.defer_fn(move_to_debug_location, 300)
end

-- Step out (dbstep out)
function M.step_out()
  if not validate_context(true) then
    return
  end

  tmux.run('dbstep out', false, false)

  -- Schedule cursor movement after stepping
  vim.defer_fn(move_to_debug_location, 300)
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

-- Show current debug location (dbstack)
function M.show_location()
  move_to_debug_location()
end

-- Evaluate expression
function M.eval_expression()
  if not validate_context(false) then
    return
  end

  local expr = vim.fn.input('Evaluate: ')
  if expr ~= '' then
    tmux.run(expr, false, false)
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
