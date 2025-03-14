-- Commands for matlab.nvim
local M = {}
local tmux = require('matlab.tmux')

-- Check if the current buffer is a MATLAB script
function M.is_matlab_script()
  local syntax = vim.bo.syntax
  if syntax == 'matlab' or syntax == 'octave' then
    return true
  end
  vim.notify('Not a MATLAB script.', vim.log.levels.WARN)
  return false
end

-- Get the MATLAB filename (without extension)
function M.get_filename()
  return vim.fn.expand('%:t'):gsub('%.m', '')
end

-- Run a MATLAB script
function M.run(command)
  if not tmux.exists() then
    return
  end

  if command then
    tmux.run(command)
  else
    -- Make sure that this is actually a MATLAB script
    if not M.is_matlab_script() then
      return
    end
    vim.cmd('write')
    tmux.run(M.get_filename())
  end
end

-- Set a breakpoint at the current line
function M.single_breakpoint()
  if not tmux.exists() or not M.is_matlab_script() then
    return
  end

  vim.cmd('write')
  local f = M.get_filename()
  local cmd = 'dbclear ' .. f .. ';dbstop ' .. f .. ' at ' .. vim.fn.line('.')
  tmux.run(cmd)
end

-- Clear breakpoints
function M.clear_breakpoint(all)
  if not tmux.exists() then
    return
  end

  if all then
    tmux.run('dbclear all')
  else
    tmux.run('dbclear ' .. M.get_filename() .. ';')
  end
end

-- Show documentation for the word under cursor
function M.doc()
  if not tmux.exists() then
    return
  end

  local r = tmux.run('help ' .. vim.fn.expand('<cword>'))
  tmux.open_pane()
  return r
end

return M