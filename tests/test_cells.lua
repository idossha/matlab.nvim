-- Cell boundary/execution regressions, 2026-09-12.
-- Ground truth: authored MATLAB sections; row numbers count the literal buffers
-- below. Run through tests/run.lua. Live MATLAB/tmux behavior is tested separately.
local cells = require('matlab.cells')
local tmux = require('matlab.tmux')

local function with_buffer(lines, row, check)
  local previous = vim.api.nvim_get_current_buf()
  local buffer = vim.api.nvim_create_buf(false, true)
  local original_exists, original_run = tmux.exists, tmux.run
  local sent = {}
  tmux.exists = function() return true end
  tmux.run = function(code) sent[#sent + 1] = code end
  local ok, err = xpcall(function()
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
    vim.bo.filetype = 'matlab'
    vim.bo.modified = false
    vim.api.nvim_win_set_cursor(0, { row, 0 })
    check(sent)
  end, debug.traceback)
  tmux.exists, tmux.run = original_exists, original_run
  vim.api.nvim_set_current_buf(previous)
  vim.api.nvim_buf_delete(buffer, { force = true })
  assert(ok, err)
end

return function(test)
  test('cell marker belongs to the section it starts', function()
    with_buffer({ '%% first', 'a = 1;', '%% second', 'b = 2;' }, 3, function()
      assert(vim.deep_equal({ cells.find_current_cell() }, { 3, 4 }))
    end)
  end)

  test('adjacent and final markers are valid empty cells', function()
    with_buffer({ 'a = 1;', '%% empty', '%% last' }, 2, function()
      assert(vim.deep_equal({ cells.find_current_cell() }, { 2, 2 }))
      vim.api.nvim_win_set_cursor(0, { 3, 0 })
      assert(vim.deep_equal({ cells.find_current_cell() }, { 3, 3 }))
      assert(vim.deep_equal(cells.get_all_cells(), {
        { start = 1, ending = 1, title = 'Beginning of file' },
        { start = 2, ending = 2, title = 'empty' },
        { start = 3, ending = 3, title = 'last' },
      }))
    end)
  end)

  test('current cell includes first unmarked line and excludes next section', function()
    with_buffer({ 'a = 1;', '%% next', 'b = 2;' }, 1, function(sent)
      cells.execute_current_cell()
      assert(vim.deep_equal(sent, { 'a = 1;' }))
    end)
  end)

  test('current cell on its marker sends only its executable lines', function()
    with_buffer({ 'a = 1;', 'a = a + 1;', '  %% next', '% comment', '', 'b = 2;', '%% later', 'c = 3;' }, 3, function(sent)
      cells.execute_current_cell()
      assert(vim.deep_equal(sent, { 'b = 2;' }))
    end)
  end)

  test('execute to cell includes preceding sections and stops at boundary', function()
    with_buffer({ 'a = 1;', '%% next', 'b = 2;', '%% last', 'c = 3;' }, 2, function(sent)
      cells.execute_to_cell()
      assert(vim.deep_equal(sent, { 'a = 1;\nb = 2;' }))
    end)
  end)

  test('last cell executes through the last buffer line', function()
    with_buffer({ 'a = 1;', '%% last', 'b = 2;', 'c = 3;' }, 4, function(sent)
      cells.execute_current_cell()
      assert(vim.deep_equal(sent, { 'b = 2;\nc = 3;' }))
    end)
  end)
end
