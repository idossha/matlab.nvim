-- Example configuration for matlab.nvim with nvim-dap-ui integration
-- Copy this to your Neovim config and customize as needed

return {
  -- Option 1: Full nvim-dap-ui integration with custom layout
  full_dapui = function()
    require('matlab').setup({
      use_dapui = true,
      dapui_config = {
        icons = { expanded = '▾', collapsed = '▸', current_frame = '▶' },
        mappings = {
          expand = { '<CR>', '<2-LeftMouse>' },
          open = 'o',
          remove = 'd',
          edit = 'e',
          repl = 'r',
          toggle = 't',
        },
        layouts = {
          {
            -- Left sidebar: debugging context
            elements = {
              { id = 'matlab_breakpoints', size = 0.30 },
              { id = 'matlab_callstack', size = 0.35 },
              { id = 'matlab_variables', size = 0.35 },
            },
            size = 40,
            position = 'left',
          },
          {
            -- Bottom panel: REPL
            elements = {
              { id = 'matlab_repl', size = 1.0 },
            },
            size = 0.25,
            position = 'bottom',
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
        render = {
          max_value_lines = 100,
        },
      },
    })
  end,

  -- Option 2: Minimal layout (REPL + breakpoints only)
  minimal_dapui = function()
    require('matlab').setup({
      use_dapui = true,
      dapui_config = {
        layouts = {
          {
            elements = {
              { id = 'matlab_repl', size = 0.6 },
              { id = 'matlab_breakpoints', size = 0.4 },
            },
            size = 50,
            position = 'right',
          },
        },
      },
    })
  end,

  -- Option 3: Custom UI (no nvim-dap-ui dependency)
  custom_ui = function()
    require('matlab').setup({
      use_dapui = false,
      debug_ui = {
        -- Custom UI configuration
        variables_position = 'right',
        variables_size = 0.3,
        callstack_position = 'bottom',
        callstack_size = 0.3,
        breakpoints_position = 'left',
        breakpoints_size = 0.25,
        repl_position = 'bottom',
        repl_size = 0.4,
      },
    })
  end,

  -- Option 4: Auto-detect (use dap-ui if available, otherwise custom)
  auto_detect = function()
    require('matlab').setup({
      -- use_dapui not specified, will auto-detect
    })
  end,

  -- Option 5: Side-by-side layout
  side_by_side = function()
    require('matlab').setup({
      use_dapui = true,
      dapui_config = {
        layouts = {
          {
            -- Left panel
            elements = {
              { id = 'matlab_variables', size = 0.5 },
              { id = 'matlab_breakpoints', size = 0.5 },
            },
            size = 0.3,
            position = 'left',
          },
          {
            -- Right panel
            elements = {
              { id = 'matlab_callstack', size = 0.3 },
              { id = 'matlab_repl', size = 0.7 },
            },
            size = 0.3,
            position = 'right',
          },
        },
      },
    })
  end,

  -- Option 6: Floating-only workflow
  floating_only = function()
    require('matlab').setup({
      use_dapui = true,
      dapui_config = {
        layouts = {},  -- No layouts, use floating windows only
      },
    })

    -- Example: Create custom keymaps for floating windows
    local debug = require('matlab.debug')
    local dap_config = require('matlab.dap_config')

    vim.keymap.set('n', '<Leader>dv', function()
      dap_config.float_element('variables', { width = 100, height = 30 })
    end, { desc = 'Float MATLAB variables' })

    vim.keymap.set('n', '<Leader>ds', function()
      dap_config.float_element('callstack', { width = 80, height = 20 })
    end, { desc = 'Float MATLAB call stack' })

    vim.keymap.set('n', '<Leader>db', function()
      dap_config.float_element('breakpoints', { width = 60, height = 25 })
    end, { desc = 'Float MATLAB breakpoints' })

    vim.keymap.set('n', '<Leader>dr', function()
      dap_config.float_element('repl', { width = 120, height = 40, enter = true })
    end, { desc = 'Float MATLAB REPL' })
  end,

  -- Example: Runtime backend switching
  setup_with_switching = function()
    -- Start with auto-detect
    require('matlab').setup({})

    -- Create commands to switch between backends
    vim.api.nvim_create_user_command('DebugWithDapUI', function()
      require('matlab.debug').set_ui_backend('dapui')
      require('matlab.debug').show_debug_ui()
    end, { desc = 'Use nvim-dap-ui for MATLAB debugging' })

    vim.api.nvim_create_user_command('DebugWithCustomUI', function()
      require('matlab.debug').set_ui_backend('custom')
      require('matlab.debug').show_debug_ui()
    end, { desc = 'Use custom UI for MATLAB debugging' })

    -- Keymaps for quick switching
    vim.keymap.set('n', '<Leader>mdd', '<cmd>DebugWithDapUI<CR>', { desc = 'Debug with DAP UI' })
    vim.keymap.set('n', '<Leader>mdc', '<cmd>DebugWithCustomUI<CR>', { desc = 'Debug with Custom UI' })
  end,

  -- Example: Lazy.nvim plugin spec with nvim-dap-ui
  lazy_plugin_spec = {
    'idohaber/matlab.nvim',
    ft = 'matlab',
    dependencies = {
      {
        'rcarriga/nvim-dap-ui',
        dependencies = {
          'mfussenegger/nvim-dap',
          'nvim-neotest/nvim-nio',
        },
      },
    },
    config = function()
      require('matlab').setup({
        use_dapui = true,
        -- Custom layout
        dapui_config = {
          layouts = {
            {
              elements = {
                { id = 'matlab_breakpoints', size = 0.25 },
                { id = 'matlab_callstack', size = 0.35 },
                { id = 'matlab_variables', size = 0.40 },
              },
              size = 45,
              position = 'left',
            },
            {
              elements = {
                { id = 'matlab_repl', size = 1.0 },
              },
              size = 0.3,
              position = 'bottom',
            },
          },
        },
      })

      -- Additional MATLAB-specific keymaps
      local matlab = require('matlab')
      vim.keymap.set('n', '<F5>', '<cmd>MatlabDebugContinue<CR>', { desc = 'Continue' })
      vim.keymap.set('n', '<F10>', '<cmd>MatlabDebugStepOver<CR>', { desc = 'Step Over' })
      vim.keymap.set('n', '<F11>', '<cmd>MatlabDebugStepInto<CR>', { desc = 'Step Into' })
      vim.keymap.set('n', '<F12>', '<cmd>MatlabDebugStepOut<CR>', { desc = 'Step Out' })
      vim.keymap.set('n', '<F9>', '<cmd>MatlabDebugToggleBreakpoint<CR>', { desc = 'Toggle Breakpoint' })
    end,
  },
}
