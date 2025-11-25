-- MATLAB DAP-UI Configuration
-- Provides default nvim-dap-ui layouts for MATLAB debugging
local M = {}

-- Default nvim-dap-ui configuration for MATLAB
M.default_config = {
  icons = { expanded = '▾', collapsed = '▸', current_frame = '▶' },
  mappings = {
    expand = { '<CR>', '<2-LeftMouse>' },
    open = 'o',
    remove = 'd',
    edit = 'e',
    repl = 'r',
    toggle = 't',
  },
  expand_lines = true,
  layouts = {
    {
      -- Left sidebar for debugging context
      elements = {
        { id = 'matlab_breakpoints', size = 0.30 },
        { id = 'matlab_callstack', size = 0.35 },
        { id = 'matlab_variables', size = 0.35 },
      },
      size = 40,
      position = 'left',
    },
    {
      -- Bottom panel for REPL and output
      elements = {
        { id = 'matlab_repl', size = 1.0 },
      },
      size = 0.25,
      position = 'bottom',
    },
  },
  controls = {
    enabled = true,
    element = 'matlab_repl',
    icons = {
      pause = '⏸',
      play = '▶',
      step_into = '↓',
      step_over = '↷',
      step_out = '↑',
      step_back = '↶',
      run_last = '▶▶',
      terminate = '⏹',
      disconnect = '⏚',
    },
  },
  floating = {
    max_height = 0.9,
    max_width = 0.9,
    border = 'rounded',
    mappings = {
      close = { 'q', '<Esc>' },
    },
  },
  windows = { indent = 1 },
  render = {
    max_type_length = nil,
    max_value_lines = 100,
  },
}

-- Apply MATLAB-specific configuration to nvim-dap-ui
function M.setup(user_config)
  local has_dapui, dapui = pcall(require, 'dapui')
  if not has_dapui then
    return false
  end

  -- Merge user config with defaults
  local config = vim.tbl_deep_extend('force', M.default_config, user_config or {})

  -- Setup dap-ui with MATLAB configuration
  dapui.setup(config)

  return true
end

-- Get a specific layout configuration
function M.get_layout(name)
  if name == 'minimal' then
    return {
      layouts = {
        {
          elements = {
            { id = 'matlab_repl', size = 0.6 },
            { id = 'matlab_breakpoints', size = 0.4 },
          },
          size = 40,
          position = 'right',
        },
      },
    }
  elseif name == 'full' then
    return M.default_config
  elseif name == 'repl_only' then
    return {
      layouts = {
        {
          elements = {
            { id = 'matlab_repl', size = 1.0 },
          },
          size = 0.3,
          position = 'bottom',
        },
      },
    }
  end

  return M.default_config
end

-- Open specific MATLAB debug UI layout
function M.open(layout_name)
  local has_dapui, dapui = pcall(require, 'dapui')
  if not has_dapui then
    vim.notify('nvim-dap-ui is not installed', vim.log.levels.ERROR)
    return
  end

  -- If layout name provided, apply it first
  if layout_name then
    local layout_config = M.get_layout(layout_name)
    M.setup(layout_config)
  end

  dapui.open()
end

-- Close all MATLAB debug UI windows
function M.close()
  local has_dapui, dapui = pcall(require, 'dapui')
  if not has_dapui then
    return
  end

  dapui.close()
end

-- Toggle MATLAB debug UI
function M.toggle()
  local has_dapui, dapui = pcall(require, 'dapui')
  if not has_dapui then
    vim.notify('nvim-dap-ui is not installed', vim.log.levels.ERROR)
    return
  end

  dapui.toggle()
end

-- Float a specific MATLAB element
function M.float_element(element_name, opts)
  local has_dapui, dapui = pcall(require, 'dapui')
  if not has_dapui then
    vim.notify('nvim-dap-ui is not installed', vim.log.levels.ERROR)
    return
  end

  local element_map = {
    variables = 'matlab_variables',
    callstack = 'matlab_callstack',
    breakpoints = 'matlab_breakpoints',
    repl = 'matlab_repl',
  }

  local elem_id = element_map[element_name] or element_name
  dapui.float_element(elem_id, opts or {})
end

-- Eval expression in MATLAB (via REPL)
function M.eval(expr)
  local has_dapui, dapui = pcall(require, 'dapui')
  if not has_dapui then
    return
  end

  -- Open REPL element with expression pre-filled
  dapui.float_element('matlab_repl', {
    width = 80,
    height = 20,
    enter = true,
  })

  -- Insert expression
  if expr then
    local tmux = require('matlab.tmux')
    if tmux.exists() then
      tmux.run(expr, false, false)
    end
  end
end

return M
