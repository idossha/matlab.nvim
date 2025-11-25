-- MATLAB Debug Module Tests
-- Comprehensive test suite for debug functionality

describe("matlab.debug", function()
  local debug
  local mock_tmux
  local mock_utils

  before_each(function()
    -- Reset module cache
    package.loaded['matlab.debug'] = nil
    package.loaded['matlab.tmux'] = nil
    package.loaded['matlab.utils'] = nil
    package.loaded['matlab.dap_elements'] = nil
    package.loaded['matlab.dap_config'] = nil

    -- Setup mocks
    mock_tmux = {
      exists = function() return true end,
      run = function() end,
    }

    mock_utils = {
      notify = function() end,
      log = function() end,
    }

    -- Inject mocks
    package.preload['matlab.tmux'] = function() return mock_tmux end
    package.preload['matlab.utils'] = function() return mock_utils end

    -- Mock nvim API
    vim = vim or {}
    vim.bo = vim.bo or {}
    vim.fn = vim.fn or {}
    vim.api = vim.api or {}
    vim.log = { levels = { ERROR = 1, WARN = 2, INFO = 3, DEBUG = 4 } }

    -- Load module
    debug = require('matlab.debug')
  end)

  describe("Module initialization", function()
    it("should export required functions", function()
      assert.is_function(debug.setup)
      assert.is_function(debug.start_debug)
      assert.is_function(debug.stop_debug)
      assert.is_function(debug.toggle_breakpoint)
      assert.is_function(debug.step_over)
      assert.is_function(debug.step_into)
      assert.is_function(debug.step_out)
      assert.is_function(debug.continue_debug)
    end)

    it("should initialize with default state", function()
      assert.is_false(debug.debug_active)
      assert.is_nil(debug.current_file)
      assert.is_nil(debug.current_line)
      assert.is_table(debug.breakpoints)
    end)
  end)

  describe("is_available", function()
    it("should return true when tmux exists", function()
      mock_tmux.exists = function() return true end
      assert.is_true(debug.is_available())
    end)

    it("should return false when tmux doesn't exist", function()
      mock_tmux.exists = function() return false end
      assert.is_false(debug.is_available())
    end)
  end)

  describe("start_debug", function()
    before_each(function()
      vim.bo.filetype = 'matlab'
      vim.bo.modified = false
      vim.fn.expand = function(arg)
        if arg == '%:t:r' then return 'test_script' end
        return ''
      end
    end)

    it("should fail if tmux not available", function()
      mock_tmux.exists = function() return false end
      local notified = false
      mock_utils.notify = function(msg, level)
        notified = true
        assert.is_string(msg)
        assert.equals(vim.log.levels.ERROR, level)
      end

      debug.start_debug()
      assert.is_true(notified)
      assert.is_false(debug.debug_active)
    end)

    it("should fail if not in MATLAB file", function()
      vim.bo.filetype = 'lua'
      local notified = false
      mock_utils.notify = function(msg, level)
        notified = true
        assert.matches("MATLAB file", msg)
      end

      debug.start_debug()
      assert.is_true(notified)
      assert.is_false(debug.debug_active)
    end)

    it("should save file if modified", function()
      vim.bo.modified = true
      local write_called = false
      vim.cmd = {
        write = function()
          write_called = true
        end
      }

      debug.start_debug()
      assert.is_true(write_called)
    end)

    it("should clear existing debug state", function()
      local commands = {}
      mock_tmux.run = function(cmd)
        table.insert(commands, cmd)
      end

      debug.start_debug()

      assert.is_true(vim.tbl_contains(commands, 'dbclear all'))
      assert.is_true(vim.tbl_contains(commands, 'dbquit'))
    end)

    it("should start debug session with correct command", function()
      local commands = {}
      mock_tmux.run = function(cmd)
        table.insert(commands, cmd)
      end

      debug.start_debug()

      local found = false
      for _, cmd in ipairs(commands) do
        if cmd:match('dbstop in test_script at 1') then
          found = true
          break
        end
      end
      assert.is_true(found)
    end)

    it("should set debug_active flag", function()
      debug.start_debug()
      assert.is_true(debug.debug_active)
    end)

    it("should set current_file", function()
      debug.start_debug()
      assert.equals('test_script', debug.current_file)
    end)
  end)

  describe("stop_debug", function()
    it("should do nothing if debug not active", function()
      debug.debug_active = false
      local run_called = false
      mock_tmux.run = function()
        run_called = true
      end

      debug.stop_debug()
      assert.is_false(run_called)
    end)

    it("should send dbquit command", function()
      debug.debug_active = true
      local quit_called = false
      mock_tmux.run = function(cmd)
        if cmd == 'dbquit' then
          quit_called = true
        end
      end

      debug.stop_debug()
      assert.is_true(quit_called)
    end)

    it("should clear debug state", function()
      debug.debug_active = true
      debug.current_file = 'test'
      debug.current_line = 42

      debug.stop_debug()

      assert.is_false(debug.debug_active)
      assert.is_nil(debug.current_file)
      assert.is_nil(debug.current_line)
    end)
  end)

  describe("toggle_breakpoint", function()
    local bufnr = 1

    before_each(function()
      vim.bo.filetype = 'matlab'
      vim.api.nvim_get_current_buf = function() return bufnr end
      vim.fn.expand = function() return 'test_script' end
      vim.fn.line = function() return 10 end
      vim.api.nvim_buf_is_valid = function() return true end
      vim.fn.sign_place = function() end
      vim.fn.sign_unplace = function() end
    end)

    it("should set breakpoint if not exists", function()
      local commands = {}
      mock_tmux.run = function(cmd)
        table.insert(commands, cmd)
      end

      debug.toggle_breakpoint()

      local found = false
      for _, cmd in ipairs(commands) do
        if cmd:match('dbstop in test_script at 10') then
          found = true
          break
        end
      end
      assert.is_true(found)
      assert.is_true(debug.breakpoints[bufnr][10])
    end)

    it("should clear breakpoint if exists", function()
      debug.breakpoints[bufnr] = { [10] = true }

      local commands = {}
      mock_tmux.run = function(cmd)
        table.insert(commands, cmd)
      end

      debug.toggle_breakpoint()

      local found = false
      for _, cmd in ipairs(commands) do
        if cmd:match('dbclear test_script at 10') then
          found = true
          break
        end
      end
      assert.is_true(found)
      assert.is_nil(debug.breakpoints[bufnr][10])
    end)

    it("should place sign when setting breakpoint", function()
      local sign_placed = false
      vim.fn.sign_place = function(id, group, name, buf, opts)
        sign_placed = true
        assert.equals('matlab_debug', group)
        assert.equals('matlab_breakpoint', name)
        assert.equals(bufnr, buf)
        assert.equals(10, opts.lnum)
      end

      debug.toggle_breakpoint()
      assert.is_true(sign_placed)
    end)

    it("should remove sign when clearing breakpoint", function()
      debug.breakpoints[bufnr] = { [10] = true }

      local sign_unplaced = false
      vim.fn.sign_unplace = function(group, opts)
        sign_unplaced = true
        assert.equals('matlab_debug', group)
        assert.equals(bufnr, opts.buffer)
      end

      debug.toggle_breakpoint()
      assert.is_true(sign_unplaced)
    end)
  end)

  describe("clear_breakpoints", function()
    it("should send dbclear all command", function()
      local clear_called = false
      mock_tmux.run = function(cmd)
        if cmd == 'dbclear all' then
          clear_called = true
        end
      end

      debug.clear_breakpoints()
      assert.is_true(clear_called)
    end)

    it("should clear breakpoints table", function()
      debug.breakpoints = {
        [1] = { [5] = true, [10] = true },
        [2] = { [3] = true }
      }

      vim.api.nvim_buf_is_valid = function() return true end
      vim.fn.sign_unplace = function() end

      debug.clear_breakpoints()

      assert.equals(0, vim.tbl_count(debug.breakpoints))
    end)

    it("should unplace all signs", function()
      debug.breakpoints = { [1] = { [5] = true } }

      local signs_unplaced = {}
      vim.api.nvim_buf_is_valid = function() return true end
      vim.fn.sign_unplace = function(group, opts)
        table.insert(signs_unplaced, { group = group, buffer = opts.buffer })
      end

      debug.clear_breakpoints()

      assert.is_true(#signs_unplaced > 0)
      assert.equals('matlab_debug', signs_unplaced[1].group)
    end)
  end)

  describe("step commands", function()
    before_each(function()
      debug.debug_active = true
    end)

    it("step_over should send dbstep command", function()
      local cmd_sent = nil
      mock_tmux.run = function(cmd)
        cmd_sent = cmd
      end

      debug.step_over()
      assert.equals('dbstep', cmd_sent)
    end)

    it("step_into should send dbstep in command", function()
      local cmd_sent = nil
      mock_tmux.run = function(cmd)
        cmd_sent = cmd
      end

      debug.step_into()
      assert.equals('dbstep in', cmd_sent)
    end)

    it("step_out should send dbstep out command", function()
      local cmd_sent = nil
      mock_tmux.run = function(cmd)
        cmd_sent = cmd
      end

      debug.step_out()
      assert.equals('dbstep out', cmd_sent)
    end)

    it("continue_debug should send dbcont command", function()
      local cmd_sent = nil
      mock_tmux.run = function(cmd)
        cmd_sent = cmd
      end

      debug.continue_debug()
      assert.equals('dbcont', cmd_sent)
    end)

    it("should fail if debug not active", function()
      debug.debug_active = false
      local notified = false
      mock_utils.notify = function(msg, level)
        notified = true
        assert.matches("No active", msg)
      end

      debug.step_over()
      assert.is_true(notified)
    end)
  end)

  describe("restore_breakpoints", function()
    it("should restore all breakpoints", function()
      debug.breakpoints = {
        [1] = { [5] = true, [10] = true },
        [2] = { [3] = true }
      }

      vim.api.nvim_buf_is_valid = function() return true end
      vim.api.nvim_buf_get_name = function(bufnr)
        return '/path/to/file' .. bufnr .. '.m'
      end
      vim.fn.fnamemodify = function(path, mod)
        if mod == ':t:r' then
          return 'file' .. path:match('%d+')
        end
      end
      vim.fn.sign_place = function() end

      local commands = {}
      mock_tmux.run = function(cmd)
        table.insert(commands, cmd)
      end

      debug.restore_breakpoints()

      -- Should have 3 breakpoints total
      local bp_count = 0
      for _, cmd in ipairs(commands) do
        if cmd:match('dbstop in') then
          bp_count = bp_count + 1
        end
      end
      assert.equals(3, bp_count)
    end)

    it("should skip invalid buffers", function()
      debug.breakpoints = {
        [999] = { [5] = true }
      }

      vim.api.nvim_buf_is_valid = function() return false end

      local commands = {}
      mock_tmux.run = function(cmd)
        table.insert(commands, cmd)
      end

      debug.restore_breakpoints()

      assert.equals(0, #commands)
    end)
  end)

  describe("get_status_string", function()
    it("should return empty string if not active", function()
      debug.debug_active = false
      assert.equals('', debug.get_status_string())
    end)

    it("should return DEBUG when active", function()
      debug.debug_active = true
      assert.matches('DEBUG', debug.get_status_string())
    end)

    it("should include filename", function()
      debug.debug_active = true
      debug.current_file = 'test_script'
      assert.matches('test_script', debug.get_status_string())
    end)

    it("should include line number", function()
      debug.debug_active = true
      debug.current_file = 'test_script'
      debug.current_line = 42
      assert.matches('42', debug.get_status_string())
    end)
  end)

  describe("get_debug_status", function()
    it("should return inactive when debug not active", function()
      debug.debug_active = false
      assert.equals('inactive', debug.get_debug_status())
    end)

    it("should return active when debug active", function()
      debug.debug_active = true
      assert.equals('active', debug.get_debug_status())
    end)
  end)
end)
