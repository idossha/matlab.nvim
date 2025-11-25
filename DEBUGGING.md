# MATLAB Debugging Guide

Complete guide for debugging MATLAB code with matlab.nvim and nvim-dap-ui.

## Table of Contents

- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Commands](#commands)
- [Keybindings](#keybindings)
- [UI Elements](#ui-elements)
- [Workflow Examples](#workflow-examples)
- [Troubleshooting](#troubleshooting)
- [Architecture](#architecture)
- [Testing](#testing)

---

## Quick Start

**Minimal setup to start debugging:**

```lua
-- In your lazy.nvim config
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
    require('matlab').setup()
  end
}
```

**Basic debug workflow:**

```vim
1. :MatlabStartServer          " Start MATLAB
2. <F9> to set breakpoints     " Or :MatlabDebugToggleBreakpoint
3. :MatlabDebugStart           " Start debug session
4. :MatlabDebugUI              " Open debug UI
5. <F5> to continue            " Or <F10> to step over
```

---

## Installation

### Requirements

- Neovim 0.7.0+
- tmux (must run Neovim inside tmux)
- MATLAB
- nvim-dap-ui plugin

### Using lazy.nvim

```lua
{
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',

    -- Add MATLAB debugging
    {
      'idohaber/matlab.nvim',
      ft = 'matlab',
      config = function()
        require('matlab').setup()
      end,
    },
  },

  config = function()
    require('dapui').setup()
    -- matlab.nvim automatically registers custom elements
  end,
}
```

### Using packer.nvim

```lua
use {
  'idohaber/matlab.nvim',
  requires = {
    'rcarriga/nvim-dap-ui',
    'mfussenegger/nvim-dap',
    'nvim-neotest/nvim-nio'
  },
  config = function()
    require('matlab').setup()
  end
}
```

---

## Configuration

### Basic Configuration

```lua
require('matlab').setup({
  -- MATLAB executable path
  executable = '/path/to/matlab',

  -- Debug UI layout (optional)
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
        size = 0.25,
        position = 'bottom',
      },
    },
  },
})
```

### Layout Presets

#### Minimal Layout (Breakpoints + REPL)

```lua
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
}
```

#### Full Layout (All elements)

```lua
dapui_config = {
  layouts = {
    {
      elements = {
        { id = 'matlab_breakpoints', size = 0.30 },
        { id = 'matlab_callstack', size = 0.35 },
        { id = 'matlab_variables', size = 0.35 },
      },
      size = 40,
      position = 'left',
    },
    {
      elements = {
        { id = 'matlab_repl', size = 1.0 },
      },
      size = 0.25,
      position = 'bottom',
    },
  },
}
```

#### Side-by-Side Layout

```lua
dapui_config = {
  layouts = {
    {
      elements = {
        { id = 'matlab_variables', size = 0.5 },
        { id = 'matlab_breakpoints', size = 0.5 },
      },
      size = 0.3,
      position = 'left',
    },
    {
      elements = {
        { id = 'matlab_callstack', size = 0.3 },
        { id = 'matlab_repl', size = 0.7 },
      },
      size = 0.3,
      position = 'right',
    },
  },
}
```

---

## Usage

### Starting a Debug Session

1. **Open MATLAB file** (`*.m`)
2. **Start MATLAB server**:
   ```vim
   :MatlabStartServer
   ```

3. **Set breakpoints** by clicking `<F9>` on desired lines

4. **Start debugging**:
   ```vim
   :MatlabDebugStart
   ```

5. **Open debug UI**:
   ```vim
   :MatlabDebugUI
   ```

### Managing Breakpoints

**Set/Toggle:**
```vim
:MatlabDebugToggleBreakpoint
" Or press <F9>
```

**Clear all:**
```vim
:MatlabDebugClearBreakpoints
```

**View breakpoints:**
```vim
:MatlabDebugShowBreakpoints
```

### Stepping Through Code

- **Continue** (`<F5>`): Resume execution until next breakpoint
- **Step Over** (`<F10>`): Execute current line, skip function calls
- **Step Into** (`<F11>`): Enter function calls
- **Step Out** (`<F12>`): Execute until current function returns

### Inspecting Variables

Open variables window:
```vim
:MatlabDebugShowVariables
```

In MATLAB REPL:
```matlab
whos           % List all variables
disp(varName)  % Display variable value
size(varName)  % Show dimensions
```

### Using MATLAB REPL

Open REPL:
```vim
:MatlabDebugShowRepl
```

In REPL window:
- Press `i` to enter insert mode
- Type MATLAB commands
- Press `<CR>` to execute
- Results appear in MATLAB pane

---

## Commands

### Debug Session

| Command | Description |
|---------|-------------|
| `:MatlabDebugStart` | Start debug session for current file |
| `:MatlabDebugStop` | Stop debug session |
| `:MatlabDebugContinue` | Continue execution (`<F5>`) |
| `:MatlabDebugStepOver` | Step over (`<F10>`) |
| `:MatlabDebugStepInto` | Step into (`<F11>`) |
| `:MatlabDebugStepOut` | Step out (`<F12>`) |

### Breakpoints

| Command | Description |
|---------|-------------|
| `:MatlabDebugToggleBreakpoint` | Toggle breakpoint at current line (`<F9>`) |
| `:MatlabDebugClearBreakpoints` | Clear all breakpoints |
| `:MatlabDebugShowBreakpoints` | Show breakpoints window |

### UI Windows

| Command | Description |
|---------|-------------|
| `:MatlabDebugUI` | Open debug UI with all elements |
| `:MatlabDebugShowVariables` | Show variables window |
| `:MatlabDebugShowCallstack` | Show call stack window |
| `:MatlabDebugShowRepl` | Show REPL window |
| `:MatlabDebugCloseUI` | Close all debug windows |

### Toggle Commands

| Command | Description |
|---------|-------------|
| `:MatlabDebugToggleVariables` | Toggle variables window |
| `:MatlabDebugToggleCallstack` | Toggle call stack window |
| `:MatlabDebugToggleBreakpoints` | Toggle breakpoints window |
| `:MatlabDebugToggleRepl` | Toggle REPL window |

---

## Keybindings

### Default Mappings (MATLAB files only)

With `<Leader>` typically set to Space:

#### Debug Control
- `<F5>` - Continue execution
- `<F9>` - Toggle breakpoint
- `<F10>` - Step over
- `<F11>` - Step into
- `<F12>` - Step out

#### Debug Session (with `<Leader>m` prefix)
- `<Leader>mds` - Start debug session
- `<Leader>mde` - Stop debug session (end)
- `<Leader>mdc` - Continue execution
- `<Leader>mdb` - Toggle breakpoint
- `<Leader>mdB` - Clear all breakpoints

#### UI Windows
- `<Leader>mdu` - Show debug UI (all elements)
- `<Leader>mdv` - Show variables
- `<Leader>mdk` - Show call stack
- `<Leader>mdp` - Show breakpoints
- `<Leader>mdr` - Show REPL
- `<Leader>mdx` - Close debug UI

#### Toggle Windows
- `<Leader>mtv` - Toggle variables
- `<Leader>mtk` - Toggle call stack
- `<Leader>mtp` - Toggle breakpoints
- `<Leader>mtr` - Toggle REPL

### Custom Keybindings

Add to your config:

```lua
vim.keymap.set('n', '<Leader>db', '<cmd>MatlabDebugToggleBreakpoint<CR>', { desc = 'Toggle Breakpoint' })
vim.keymap.set('n', '<Leader>du', '<cmd>MatlabDebugUI<CR>', { desc = 'Debug UI' })
vim.keymap.set('n', '<Leader>dr', '<cmd>MatlabDebugShowRepl<CR>', { desc = 'REPL' })
```

---

## UI Elements

matlab.nvim registers 4 custom elements with nvim-dap-ui:

### 1. Variables Window (`matlab_variables`)

Shows MATLAB workspace variables.

**Features:**
- Lists all workspace variables
- Executes `whos` command on render
- Tips for variable inspection
- Works without active debug session

**Usage:**
```vim
:MatlabDebugShowVariables
```

In MATLAB pane, run `whos` for detailed variable information.

### 2. Call Stack Window (`matlab_callstack`)

Shows debug execution stack.

**Features:**
- Current stack trace
- Executes `dbstack` command
- Stack navigation commands
- Updates on step commands

**Usage:**
```vim
:MatlabDebugShowCallstack
```

### 3. Breakpoints Window (`matlab_breakpoints`)

Lists all active breakpoints.

**Features:**
- Groups breakpoints by file
- Shows line numbers
- Total count
- Management commands

**Usage:**
```vim
:MatlabDebugShowBreakpoints
```

### 4. REPL Window (`matlab_repl`)

Interactive MATLAB command execution.

**Features:**
- Execute any MATLAB command
- Command history tracking (last 10 commands)
- Results in MATLAB pane
- Insert mode support

**Usage:**
```vim
:MatlabDebugShowRepl
```

**In REPL:**
- `i` - Enter insert mode
- `A` - Append at end of line
- `<CR>` - Execute command
- `q`, `<Esc>`, `<C-c>` - Close window

---

## Workflow Examples

### Example 1: Debug Simple Script

```matlab
% myScript.m
function result = myScript()
    x = 1:10;
    y = x.^2;
    result = sum(y);
end
```

**Debug steps:**

1. Open file in Neovim
2. `:MatlabStartServer`
3. Set breakpoint on line 3 (`<F9>`)
4. `:MatlabDebugStart`
5. `:MatlabDebugUI`
6. Press `<F10>` to step through
7. In REPL: `disp(x)` to see values
8. Press `<F5>` to continue

### Example 2: Debug with Function Calls

```matlab
% main.m
function main()
    data = loadData();
    result = processData(data);
    display(result);
end

function data = loadData()
    data = rand(100, 1);  % Breakpoint here
end

function result = processData(data)
    result = mean(data);   % Breakpoint here
end
```

**Debug steps:**

1. Set breakpoints in both `loadData` and `processData`
2. `:MatlabDebugStart`
3. `:MatlabDebugUI`
4. Hit first breakpoint in `loadData`
5. Check variables: `:MatlabDebugShowVariables`
6. Press `<F12>` to step out to `main`
7. Press `<F11>` to step into `processData`
8. Check call stack: `:MatlabDebugShowCallstack`

### Example 3: Using REPL for Inspection

At any breakpoint:

```vim
:MatlabDebugShowRepl
```

In REPL window (press `i`):

```matlab
whos                    % See all variables
disp(variableName)      % Display value
size(matrix)            % Check dimensions
class(variable)         % Check type
fieldnames(struct)      % Struct fields
```

---

## Troubleshooting

### MATLAB Pane Not Available

**Problem:** Error message "MATLAB pane not available"

**Solution:**
```vim
:MatlabStartServer
```

Ensure you're running Neovim in tmux:
```bash
tmux
nvim myfile.m
```

### Debug UI Doesn't Appear

**Problem:** `:MatlabDebugUI` does nothing

**Solutions:**

1. Check nvim-dap-ui is installed:
   ```vim
   :lua print(vim.inspect(require('dapui')))
   ```

2. Verify elements are registered:
   ```vim
   :lua require('matlab.dap_elements').register_all()
   ```

3. Check for errors:
   ```vim
   :messages
   ```

### Breakpoints Not Working

**Problem:** Breakpoints don't stop execution

**Solutions:**

1. Ensure file is saved
2. Check breakpoint is set:
   ```vim
   :MatlabDebugShowBreakpoints
   ```

3. Verify MATLAB received command (check MATLAB pane)

4. Try clearing and re-setting:
   ```vim
   :MatlabDebugClearBreakpoints
   <F9> to set again
   ```

### REPL Commands Not Executing

**Problem:** Typing in REPL doesn't execute commands

**Solutions:**

1. Press `i` to enter insert mode
2. Ensure command ends with `<CR>`
3. Check MATLAB pane is active
4. Verify tmux connection:
   ```vim
   :lua print(require('matlab.tmux').exists())
   ```

### Signs Not Showing

**Problem:** Breakpoint signs don't appear in signcolumn

**Solutions:**

1. Enable signcolumn:
   ```vim
   :set signcolumn=yes
   ```

2. Check sign is defined:
   ```vim
   :sign list
   ```

3. Re-initialize signs:
   ```vim
   :lua require('matlab.debug').setup_debug_ui()
   ```

### Elements Not Found

**Problem:** Error about matlab_* elements not found

**Solution:**

Manually register elements:
```vim
:lua require('matlab.dap_elements').register_all()
```

Ensure nvim-dap-ui is loaded before matlab.nvim.

---

## Architecture

### Component Overview

```
matlab.nvim/
├── lua/matlab/
│   ├── debug.lua          # Core debug logic
│   ├── dap_elements.lua   # nvim-dap-ui elements
│   ├── dap_config.lua     # Layout & configuration
│   └── tmux.lua           # MATLAB communication
```

### Debug Flow

```
User Action
    ↓
debug.lua (Core Logic)
    ↓
tmux.lua (Send Command)
    ↓
MATLAB Process
    ↓
dap_elements.lua (Update UI)
    ↓
nvim-dap-ui (Render)
```

### Element Registration

During `setup()`:

1. `debug.lua` calls `dap_elements.register_all()`
2. Each element is registered with dapui:
   - `matlab_variables`
   - `matlab_callstack`
   - `matlab_breakpoints`
   - `matlab_repl`
3. `dap_config.setup()` applies layout configuration
4. Elements become available in dap-ui layouts

### Element Interface

Each element implements:

```lua
{
  render = function()
    -- Update buffer content
  end,

  buffer = function()
    -- Return element's buffer number
  end,

  float_defaults = function()
    -- Return default float dimensions
    return { width = 80, height = 25 }
  end,

  allow_without_session = true  -- Can open without debug session
}
```

### State Management

Debug state stored in `debug.lua`:

```lua
M.debug_active = false      -- Session active?
M.current_file = nil        -- Current debugging file
M.current_line = nil        -- Current line number
M.breakpoints = {}          -- Breakpoints by buffer
```

Breakpoints structure:
```lua
{
  [bufnr] = {
    [line] = true,
    [line] = true,
  }
}
```

---

## Testing

Comprehensive test suite ensures reliability.

### Running Tests

Using plenary.nvim:

```vim
:PlenaryBustedDirectory tests/
```

Using busted:

```bash
cd /path/to/matlab.nvim
busted tests/
```

### Test Coverage

- **debug.lua**: ~85% coverage
  - Session management
  - Breakpoint operations
  - Step commands
  - State handling

- **dap_elements.lua**: ~80% coverage
  - Element interface
  - Rendering logic
  - Registration system

See `tests/README.md` for detailed testing documentation.

### Writing Tests

Example test:

```lua
describe("debug.start_debug", function()
  it("should set debug_active flag", function()
    debug.start_debug()
    assert.is_true(debug.debug_active)
  end)
end)
```

---

## Advanced Usage

### Custom Layouts

Create dynamic layouts:

```lua
local function create_layout(style)
  if style == 'compact' then
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
  -- ... more layouts
end

require('matlab').setup({
  dapui_config = create_layout('compact')
})
```

### Statusline Integration

Show debug status in statusline:

```lua
-- In your statusline config
local function matlab_debug_status()
  local debug = require('matlab.debug')
  return debug.get_status_string()
end

-- For lualine
sections = {
  lualine_x = { matlab_debug_status }
}
```

### Auto-commands

Auto-open debug UI on session start:

```lua
vim.api.nvim_create_autocmd('User', {
  pattern = 'MatlabDebugStarted',
  callback = function()
    vim.cmd('MatlabDebugUI')
  end,
})
```

### Floating Element Shortcuts

Quick access to individual elements:

```lua
vim.keymap.set('n', '<Leader>mv', function()
  require('matlab.dap_config').float_element('variables', {
    width = 100,
    height = 30,
  })
end, { desc = 'Float Variables' })
```

---

## Best Practices

1. **Save files before debugging** - Breakpoints apply to saved content

2. **Use meaningful variable names** - Easier to inspect in variables window

3. **Clear breakpoints when done** - Prevent unexpected stops later

4. **Check MATLAB pane** - Detailed output appears there

5. **Use REPL for quick checks** - Faster than opening variables window

6. **Step over libraries** - Use `<F10>` for built-in functions

7. **Monitor call stack** - Understand execution context

8. **Close UI when done** - Free up screen space with `:MatlabDebugCloseUI`

---

## FAQ

**Q: Can I use this without nvim-dap?**
A: No, nvim-dap-ui is required for the debug UI.

**Q: Does this work outside tmux?**
A: No, tmux is required for MATLAB communication.

**Q: Can I debug on a remote server?**
A: Yes, if you can access MATLAB via tmux on that server.

**Q: How do I set conditional breakpoints?**
A: Use MATLAB's `dbstop` with conditions in the REPL.

**Q: Can I debug Simulink models?**
A: No, only MATLAB `.m` files are supported.

**Q: Does it work with Octave?**
A: Not tested, but should work if Octave supports `dbstop`/`dbstep`.

---

## Contributing

Found a bug or want to add a feature?

1. Check existing issues
2. Write tests for new features
3. Update this documentation
4. Submit PR with clear description

See `tests/README.md` for testing guidelines.

---

## Resources

- [nvim-dap-ui documentation](https://github.com/rcarriga/nvim-dap-ui)
- [MATLAB Debugging Documentation](https://www.mathworks.com/help/matlab/debugging-code.html)
- [tmux documentation](https://github.com/tmux/tmux/wiki)

---

## License

Same as matlab.nvim - see main README.
