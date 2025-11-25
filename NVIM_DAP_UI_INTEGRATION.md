# nvim-dap-ui Integration Guide

## Overview

matlab.nvim now supports **dual UI backends** for debugging:
1. **Custom UI** - The original lightweight floating window implementation
2. **nvim-dap-ui** - Integration with the popular nvim-dap-ui plugin for a consistent debugging experience

You can use either backend or switch between them at runtime!

## Installation

### Option 1: With nvim-dap-ui (Recommended)

Install nvim-dap-ui alongside matlab.nvim:

```lua
-- Using lazy.nvim
{
  'idohaber/matlab.nvim',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    dependencies = {
      'mfussenegger/nvim-dap',
      'nvim-neotest/nvim-nio'
    }
  },
  config = function()
    require('matlab').setup({
      use_dapui = true,  -- Auto-detect and use nvim-dap-ui if available
    })
  end
}
```

### Option 2: Custom UI Only

If you prefer the lightweight custom UI:

```lua
{
  'idohaber/matlab.nvim',
  config = function()
    require('matlab').setup({
      use_dapui = false,  -- Explicitly use custom UI
    })
  end
}
```

## Configuration

### Basic Setup (Auto-detect)

By default, matlab.nvim automatically detects if nvim-dap-ui is installed:

```lua
require('matlab').setup()  -- Will use dap-ui if available, otherwise custom UI
```

### Explicit Backend Selection

```lua
require('matlab').setup({
  use_dapui = true,  -- Force nvim-dap-ui backend
  -- or
  use_dapui = false,  -- Force custom UI backend
})
```

### Custom nvim-dap-ui Layout

You can customize the nvim-dap-ui layout for MATLAB debugging:

```lua
require('matlab').setup({
  use_dapui = true,
  dapui_config = {
    layouts = {
      {
        -- Custom layout configuration
        elements = {
          { id = 'matlab_breakpoints', size = 0.25 },
          { id = 'matlab_variables', size = 0.40 },
          { id = 'matlab_callstack', size = 0.35 },
        },
        size = 50,  -- Width in columns
        position = 'left',
      },
      {
        elements = {
          { id = 'matlab_repl', size = 1.0 },
        },
        size = 0.3,  -- 30% of screen height
        position = 'bottom',
      },
    },
  },
})
```

### Available Layout Presets

The plugin includes several layout presets:

```lua
-- Full layout (default)
:MatlabDebugUI

-- Minimal layout (breakpoints + REPL only)
require('matlab.dap_config').open('minimal')

-- REPL only
require('matlab.dap_config').open('repl_only')
```

## Usage

### Commands

All existing commands work with both UI backends:

```vim
" Open debug UI (uses configured backend)
:MatlabDebugUI

" Show individual windows as floating windows
:MatlabDebugShowVariables
:MatlabDebugShowCallstack
:MatlabDebugShowBreakpoints
:MatlabDebugShowRepl

" Toggle windows
:MatlabDebugToggleVariables
:MatlabDebugToggleCallstack
:MatlabDebugToggleBreakpoints
:MatlabDebugToggleRepl

" Close all debug UI windows
:MatlabDebugCloseUI

" Switch UI backend at runtime
:MatlabDebugSetUI dapui   " Switch to nvim-dap-ui
:MatlabDebugSetUI custom  " Switch to custom UI
```

### Lua API

```lua
local debug = require('matlab.debug')

-- Open debug UI
debug.show_debug_ui()

-- Show individual elements
debug.show_variables()
debug.show_callstack()
debug.show_breakpoints()
debug.show_repl()

-- Switch backend programmatically
debug.set_ui_backend('dapui')   -- Use nvim-dap-ui
debug.set_ui_backend('custom')  -- Use custom UI

-- Close UI
debug.close_ui()
```

### Key Mappings

With default mappings (`<Leader>m` prefix):

```
<Leader>mdu    - Show debug UI
<Leader>mdv    - Show variables window
<Leader>mdk    - Show call stack window
<Leader>mdp    - Show breakpoints window
<Leader>mdr    - Show REPL window
<Leader>mdx    - Close all debug windows

<Leader>mtv    - Toggle variables window
<Leader>mtk    - Toggle call stack window
<Leader>mtp    - Toggle breakpoints window
<Leader>mtr    - Toggle REPL window
```

## Custom nvim-dap-ui Elements

matlab.nvim registers four custom elements with nvim-dap-ui:

### 1. `matlab_variables`
- Shows MATLAB workspace variables
- Executes `whos` command in MATLAB
- Provides tips for variable inspection

### 2. `matlab_callstack`
- Shows debug call stack
- Executes `dbstack` command in MATLAB
- Displays stack navigation commands

### 3. `matlab_breakpoints`
- Lists all active breakpoints by file
- Shows total breakpoint count
- Provides breakpoint management commands

### 4. `matlab_repl`
- Interactive MATLAB command execution
- Command history tracking
- Direct integration with MATLAB pane

## Element Interface

Each element implements the `dapui.Element` interface:

```lua
-- Example: Custom element structure
{
  render = function()
    -- Update buffer content
  end,

  buffer = function()
    -- Return current buffer number
  end,

  float_defaults = function()
    -- Return default float dimensions
    return { width = 80, height = 25 }
  end,

  allow_without_session = true  -- Can open without active debug session
}
```

## Advanced Usage

### Floating Individual Elements

You can float any MATLAB debug element:

```lua
local dap_config = require('matlab.dap_config')

-- Float MATLAB variables window
dap_config.float_element('variables', {
  width = 100,
  height = 30,
  enter = true,  -- Focus the window
})

-- Float REPL with custom size
dap_config.float_element('repl', {
  width = 120,
  height = 40,
  enter = true,
})
```

### Programmatic Layout Switching

```lua
local dap_config = require('matlab.dap_config')

-- Switch to minimal layout
dap_config.open('minimal')

-- Switch to full layout
dap_config.open('full')

-- Switch to REPL-only layout
dap_config.open('repl_only')
```

### Eval Expression in REPL

```lua
local dap_config = require('matlab.dap_config')

-- Evaluate MATLAB expression
dap_config.eval('whos')
dap_config.eval('disp(myVariable)')
```

## Architecture

### Module Structure

```
lua/matlab/
├── debug.lua           - Core debug logic (backend-agnostic)
├── debug_ui.lua        - Custom floating window UI
├── dap_elements.lua    - nvim-dap-ui element implementations
└── dap_config.lua      - nvim-dap-ui configuration and helpers
```

### Backend Selection Flow

```
matlab.setup()
    ↓
debug.setup(opts)
    ↓
Check use_dapui option
    ↓
┌─────────────────┐         ┌──────────────────┐
│   dapui: true   │         │  dapui: false    │
│                 │         │                  │
│ 1. Load         │         │ 1. Load custom   │
│    dap_elements │         │    debug_ui      │
│ 2. Register     │         │ 2. Setup         │
│    elements     │         │    autocmds      │
│ 3. Setup        │         │ 3. Ready         │
│    dap-ui       │         │                  │
└─────────────────┘         └──────────────────┘
```

### Element Registration

When nvim-dap-ui is available:

```lua
-- Automatic registration during setup
dapui.register_element('matlab_variables', variables_element)
dapui.register_element('matlab_callstack', callstack_element)
dapui.register_element('matlab_breakpoints', breakpoints_element)
dapui.register_element('matlab_repl', repl_element)
```

## Comparison: Custom UI vs nvim-dap-ui

| Feature | Custom UI | nvim-dap-ui |
|---------|-----------|-------------|
| Installation | No dependencies | Requires nvim-dap-ui |
| Startup time | Faster | Slightly slower |
| Layout flexibility | Fixed positions | Highly configurable |
| Consistency | Custom design | Matches other DAP UIs |
| Window management | Manual toggle | Integrated layouts |
| Integration | MATLAB-only | Works with all DAP adapters |
| Resource usage | Lighter | Heavier |
| Customization | Limited | Extensive |

## Best Practices

### 1. Choose Your Backend Based on Needs

**Use Custom UI if:**
- You only debug MATLAB
- You want minimal dependencies
- You prefer lightweight plugins
- You like the current floating window UX

**Use nvim-dap-ui if:**
- You debug multiple languages
- You want a consistent debugging experience
- You need advanced layout customization
- You already use nvim-dap for other languages

### 2. Runtime Switching

You can switch backends without restarting Neovim:

```vim
" Start with custom UI
:MatlabDebugUI

" Switch to dap-ui
:MatlabDebugSetUI dapui
:MatlabDebugUI  " Now opens dap-ui layout

" Switch back
:MatlabDebugSetUI custom
```

### 3. Hybrid Workflow

Mix and match features from both backends:

```lua
-- Use dap-ui layouts for full debugging sessions
debug.set_ui_backend('dapui')
debug.show_debug_ui()  -- Full layout

-- Use custom UI for quick REPL access
debug.set_ui_backend('custom')
debug.show_repl()  -- Lightweight floating REPL
```

## Troubleshooting

### nvim-dap-ui Not Detected

**Problem:** Plugin uses custom UI even though nvim-dap-ui is installed.

**Solution:**
```lua
-- Explicitly enable dap-ui
require('matlab').setup({ use_dapui = true })

-- Or check if dap-ui is loadable
:lua print(pcall(require, 'dapui'))
```

### Element Registration Failed

**Problem:** Error messages about element registration.

**Solution:**
```lua
-- Ensure nvim-dap-ui is properly installed and loaded
require('dapui').setup()  -- Setup dap-ui first
require('matlab').setup({ use_dapui = true })
```

### Layout Not Appearing

**Problem:** `:MatlabDebugUI` doesn't show windows.

**Solution:**
```vim
" Check which backend is active
:lua print(require('matlab.debug').use_dapui)

" Try explicit backend switch
:MatlabDebugSetUI dapui
:MatlabDebugUI
```

### REPL Not Executing Commands

**Problem:** Commands in REPL don't execute in MATLAB.

**Solution:**
- Ensure MATLAB pane is running: `:MatlabStartServer`
- Check tmux connection: `:lua require('matlab.tmux').exists()`
- Try executing in MATLAB pane directly

## Migration Guide

### From Custom UI to nvim-dap-ui

1. Install nvim-dap-ui:
```lua
{
  'rcarriga/nvim-dap-ui',
  dependencies = { 'mfussenegger/nvim-dap', 'nvim-neotest/nvim-nio' }
}
```

2. Update matlab.nvim config:
```lua
require('matlab').setup({
  use_dapui = true,
})
```

3. All your existing commands and keymaps continue to work!

### Keeping Both Options

```lua
-- Let users choose at runtime
vim.api.nvim_create_user_command('MatlabDebugDapUI', function()
  require('matlab.debug').set_ui_backend('dapui')
  require('matlab.debug').show_debug_ui()
end, {})

vim.api.nvim_create_user_command('MatlabDebugCustom', function()
  require('matlab.debug').set_ui_backend('custom')
  require('matlab.debug').show_debug_ui()
end, {})
```

## Future Enhancements

Possible future improvements:
1. Parse MATLAB output to populate elements with real data
2. Full DAP adapter implementation for MATLAB
3. Bidirectional navigation (click on stack frame to jump to file)
4. Variable tree expansion (structs, cells, arrays)
5. Conditional breakpoints via MATLAB dbstop conditions
6. Watch expressions with auto-refresh

## Contributing

To add new nvim-dap-ui elements:

1. Create element in `lua/matlab/dap_elements.lua`:
```lua
M.my_element = {}

function M.my_element.render()
  -- Update content
end

function M.my_element.buffer()
  -- Return buffer
end

M.my_element.allow_without_session = true
```

2. Register in `M.register_all()`:
```lua
dapui.register_element('matlab_my_element', M.my_element)
```

3. Add to layouts in `lua/matlab/dap_config.lua`:
```lua
elements = {
  { id = 'matlab_my_element', size = 0.25 },
  -- ...
}
```

## References

- [nvim-dap-ui Documentation](https://github.com/rcarriga/nvim-dap-ui)
- [nvim-dap Documentation](https://github.com/mfussenegger/nvim-dap)
- [Debug Adapter Protocol Specification](https://microsoft.github.io/debug-adapter-protocol/)
