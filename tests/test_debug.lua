-- Debug command/sign regressions, 2026-09-12. Ground truth: authored MATLAB
-- debugger commands and expected sign rows in the literal buffer below.
-- Run: nvim --headless -u NONE -l tests/run.lua. Live MATLAB is separate.
local debugger = require('matlab.debug')
local tmux = require('matlab.tmux')

local function with_debug_buffer(check)
  local previous = vim.api.nvim_get_current_buf()
  local buffer = vim.api.nvim_create_buf(false, true)
  local old_exists, old_run = tmux.exists, tmux.run
  local old_active, old_breakpoints = debugger.debug_active, debugger.breakpoints
  local sent = {}
  tmux.exists = function() return true end
  tmux.run = function(...) sent[#sent + 1] = { ... } end
  debugger.debug_active, debugger.breakpoints = false, {}
  local ok, err = xpcall(function()
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_name(buffer, vim.fn.tempname() .. '/debug_fixture.m')
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { 'a = 1;', 'b = 2;', 'c = 3;' })
    vim.bo.filetype = 'matlab'
    vim.bo.modified = false
    debugger.setup_signs()
    check(buffer, sent)
  end, debug.traceback)
  -- Step/continue callbacks are deferred by up to 200 ms. Disable the session
  -- before draining them so no location retries or real transport can escape.
  debugger.debug_active = false
  vim.wait(250, function() return false end, 10)
  debugger.debug_active, debugger.breakpoints = old_active, old_breakpoints
  tmux.exists, tmux.run = old_exists, old_run
  vim.api.nvim_set_current_buf(previous)
  vim.api.nvim_buf_delete(buffer, { force = true })
  assert(ok, err)
end

local function signs(buffer, group)
  return vim.fn.sign_getplaced(buffer, { group = group })[1].signs
end

return function(test)
  test('breakpoint toggle places and removes the matching sign and MATLAB breakpoint', function()
    with_debug_buffer(function(buffer, sent)
      vim.api.nvim_win_set_cursor(0, { 2, 0 })
      debugger.toggle_breakpoint()
      local placed = signs(buffer, debugger.sign_group_bp)
      assert(#placed == 1 and placed[1].lnum == 2 and placed[1].name == 'matlab_breakpoint')
      assert(debugger.breakpoints[buffer][2] == true)
      debugger.toggle_breakpoint()
      assert(#signs(buffer, debugger.sign_group_bp) == 0)
      assert(debugger.breakpoints[buffer][2] == nil)
      assert(vim.deep_equal(sent, {
        { 'dbstop in debug_fixture at 2', false, false },
        { 'dbclear debug_fixture at 2', false, false },
      }))
    end)
  end)

  test('clearing breakpoints preserves the current debug line sign', function()
    with_debug_buffer(function(buffer, sent)
      debugger.toggle_breakpoint()
      vim.api.nvim_win_set_cursor(0, { 3, 0 })
      debugger.toggle_breakpoint()
      assert(#signs(buffer, debugger.sign_group_bp) == 2)
      vim.fn.sign_place(999999, debugger.sign_group_line, 'matlab_debug_line', buffer, { lnum = 2 })
      debugger.clear_breakpoints()
      assert(#signs(buffer, debugger.sign_group_bp) == 0)
      assert(vim.deep_equal(debugger.breakpoints, {}))
      local location = signs(buffer, debugger.sign_group_line)
      assert(#location == 1 and location[1].lnum == 2)
      assert(vim.deep_equal(sent[#sent], { 'dbclear all', false, false }))
    end)
  end)

  test('continue and stepping preserve the active debugger without Ctrl-C', function()
    with_debug_buffer(function(_, sent)
      debugger.debug_active = true
      debugger.continue_debug()
      debugger.step_over()
      debugger.step_into()
      debugger.step_out()
      assert(vim.deep_equal(sent, {
        { 'dbcont', true, true }, { 'dbstep', true, true },
        { 'dbstep in', true, true }, { 'dbstep out', true, true },
      }))
    end)
  end)

  test('inactive debugger refuses continue and stepping commands', function()
    with_debug_buffer(function(_, sent)
      debugger.continue_debug()
      debugger.step_over()
      debugger.step_into()
      debugger.step_out()
      assert(#sent == 0)
    end)
  end)
end
