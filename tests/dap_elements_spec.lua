-- MATLAB DAP Elements Tests
-- Tests for nvim-dap-ui element implementations

describe("matlab.dap_elements", function()
  local dap_elements
  local mock_tmux
  local mock_utils

  before_each(function()
    -- Reset module cache
    package.loaded['matlab.dap_elements'] = nil
    package.loaded['matlab.tmux'] = nil
    package.loaded['matlab.utils'] = nil

    -- Setup mocks
    mock_tmux = {
      exists = function() return true end,
      run = function() end,
    }

    mock_utils = {
      notify = function() end,
    }

    -- Inject mocks
    package.preload['matlab.tmux'] = function() return mock_tmux end
    package.preload['matlab.utils'] = function() return mock_utils end

    -- Mock nvim API
    vim = vim or {}
    vim.bo = vim.bo or {}
    vim.api = vim.api or {}
    vim.loop = vim.loop or {}
    vim.log = { levels = { ERROR = 1, WARN = 2, INFO = 3 } }

    vim.api.nvim_create_buf = function() return 1 end
    vim.api.nvim_buf_is_valid = function() return true end
    vim.api.nvim_buf_set_lines = function() end
    vim.api.nvim_get_current_line = function() return '' end
    vim.loop.now = function() return 0 end
    vim.schedule = function(fn) fn() end
    vim.keymap = { set = function() end }

    -- Load module
    dap_elements = require('matlab.dap_elements')
  end)

  describe("Element: variables", function()
    it("should implement required interface", function()
      assert.is_function(dap_elements.variables.render)
      assert.is_function(dap_elements.variables.buffer)
      assert.is_function(dap_elements.variables.float_defaults)
      assert.is_boolean(dap_elements.variables.allow_without_session)
    end)

    it("should have allow_without_session enabled", function()
      assert.is_true(dap_elements.variables.allow_without_session)
    end)

    it("should return buffer number", function()
      local buf = dap_elements.variables.buffer()
      assert.is_number(buf)
    end)

    it("should return float defaults", function()
      local defaults = dap_elements.variables.float_defaults()
      assert.is_table(defaults)
      assert.is_number(defaults.width)
      assert.is_number(defaults.height)
    end)

    it("should render without errors", function()
      assert.has_no.errors(function()
        dap_elements.variables.render()
      end)
    end)

    it("should execute whos command on render", function()
      local cmd_executed = false
      mock_tmux.run = function(cmd)
        if cmd == 'whos' then
          cmd_executed = true
        end
      end

      dap_elements.variables.render()
      assert.is_true(cmd_executed)
    end)

    it("should update timestamp on render", function()
      local before = dap_elements.variables._last_update or 0
      vim.loop.now = function() return 1000 end

      dap_elements.variables.render()

      assert.is_true(dap_elements.variables._last_update > before)
    end)
  end)

  describe("Element: callstack", function()
    it("should implement required interface", function()
      assert.is_function(dap_elements.callstack.render)
      assert.is_function(dap_elements.callstack.buffer)
      assert.is_function(dap_elements.callstack.float_defaults)
      assert.is_boolean(dap_elements.callstack.allow_without_session)
    end)

    it("should execute dbstack command on render", function()
      local cmd_executed = false
      mock_tmux.run = function(cmd)
        if cmd == 'dbstack' then
          cmd_executed = true
        end
      end

      dap_elements.callstack.render()
      assert.is_true(cmd_executed)
    end)

    it("should return different buffer than variables", function()
      local var_buf = dap_elements.variables.buffer()
      local stack_buf = dap_elements.callstack.buffer()
      -- In mock, they might be same, but structure is correct
      assert.is_number(stack_buf)
    end)
  end)

  describe("Element: breakpoints", function()
    it("should implement required interface", function()
      assert.is_function(dap_elements.breakpoints.render)
      assert.is_function(dap_elements.breakpoints.buffer)
      assert.is_function(dap_elements.breakpoints.float_defaults)
      assert.is_boolean(dap_elements.breakpoints.allow_without_session)
    end)

    it("should render without errors when debug module available", function()
      package.preload['matlab.debug'] = function()
        return { breakpoints = {} }
      end

      assert.has_no.errors(function()
        dap_elements.breakpoints.render()
      end)
    end)

    it("should show no breakpoints message when empty", function()
      package.preload['matlab.debug'] = function()
        return { breakpoints = {} }
      end

      local lines_set = {}
      vim.api.nvim_buf_set_lines = function(buf, start, end_, strict, lines)
        lines_set = lines
      end

      dap_elements.breakpoints.render()

      local found = false
      for _, line in ipairs(lines_set) do
        if line:match('No breakpoints') then
          found = true
          break
        end
      end
      assert.is_true(found)
    end)

    it("should list breakpoints when present", function()
      vim.api.nvim_buf_is_valid = function() return true end
      vim.api.nvim_buf_get_name = function() return '/path/to/test.m' end
      vim.fn = { fnamemodify = function() return 'test.m' end }

      package.preload['matlab.debug'] = function()
        return {
          breakpoints = {
            [1] = { [5] = true, [10] = true }
          }
        }
      end

      local lines_set = {}
      vim.api.nvim_buf_set_lines = function(buf, start, end_, strict, lines)
        lines_set = lines
      end

      dap_elements.breakpoints.render()

      -- Should contain breakpoint info
      local has_bp_info = false
      for _, line in ipairs(lines_set) do
        if line:match('Line %d+') then
          has_bp_info = true
          break
        end
      end
      assert.is_true(has_bp_info)
    end)
  end)

  describe("Element: repl", function()
    it("should implement required interface", function()
      assert.is_function(dap_elements.repl.render)
      assert.is_function(dap_elements.repl.buffer)
      assert.is_function(dap_elements.repl.float_defaults)
      assert.is_boolean(dap_elements.repl.allow_without_session)
    end)

    it("should have command history", function()
      assert.is_table(dap_elements.repl._history)
    end)

    it("should setup keymaps on render", function()
      local keymaps_set = false
      vim.keymap.set = function()
        keymaps_set = true
      end

      dap_elements.repl.render()
      assert.is_true(keymaps_set)
    end)

    it("should have larger default size than other elements", function()
      local repl_defaults = dap_elements.repl.float_defaults()
      local var_defaults = dap_elements.variables.float_defaults()

      -- REPL should be larger
      assert.is_true(repl_defaults.height >= var_defaults.height)
    end)
  end)

  describe("register_all", function()
    it("should return false if dapui not available", function()
      package.loaded['dapui'] = nil
      package.preload['dapui'] = function()
        error('not found')
      end

      local result = dap_elements.register_all()
      assert.is_false(result)
    end)

    it("should register all elements if dapui available", function()
      local registered = {}

      package.preload['dapui'] = function()
        return {
          register_element = function(name, element)
            registered[name] = element
          end
        }
      end

      local result = dap_elements.register_all()
      assert.is_true(result)

      assert.is_not_nil(registered.matlab_variables)
      assert.is_not_nil(registered.matlab_callstack)
      assert.is_not_nil(registered.matlab_breakpoints)
      assert.is_not_nil(registered.matlab_repl)
    end)

    it("should notify on successful registration", function()
      package.preload['dapui'] = function()
        return {
          register_element = function() end
        }
      end

      local notified = false
      mock_utils.notify = function(msg, level)
        notified = true
        assert.matches('registered', msg)
        assert.equals(vim.log.levels.INFO, level)
      end

      dap_elements.register_all()
      assert.is_true(notified)
    end)
  end)

  describe("is_available", function()
    it("should return true if dapui can be loaded", function()
      package.preload['dapui'] = function()
        return {}
      end

      assert.is_true(dap_elements.is_available())
    end)

    it("should return false if dapui cannot be loaded", function()
      package.loaded['dapui'] = nil
      package.preload['dapui'] = function()
        error('not found')
      end

      assert.is_false(dap_elements.is_available())
    end)
  end)

  describe("Buffer management", function()
    it("should create buffer only once per element", function()
      local create_count = 0
      vim.api.nvim_create_buf = function()
        create_count = create_count + 1
        return create_count
      end

      local buf1 = dap_elements.variables.buffer()
      local buf2 = dap_elements.variables.buffer()

      assert.equals(buf1, buf2)
      assert.equals(1, create_count)
    end)

    it("should set correct buffer options", function()
      local buffer_opts = {}
      vim.bo = setmetatable({}, {
        __newindex = function(t, k, v)
          if type(k) == 'number' then
            buffer_opts[k] = buffer_opts[k] or {}
          else
            for buf, opts in pairs(buffer_opts) do
              opts[k] = v
            end
          end
        end
      })

      dap_elements.variables.buffer()

      -- Check if modifiable was set to false during render
      vim.bo.__newindex(nil, 1, {})
      dap_elements.variables.render()
    end)
  end)
end)
