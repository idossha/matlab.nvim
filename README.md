# matlab.nvim

A modern Neovim plugin for MATLAB integration with tmux. This plugin provides seamless integration between Neovim, MATLAB, and tmux, making your MATLAB development workflow efficient and productive.

Inspired by [MortenStabenau/matlab-vim](https://github.com/MortenStabenau/matlab-vim), rewritten in Lua for Neovim with a modular architecture and enhanced functionality.

**Contributions are welcome!** This plugin is actively maintained and we encourage community involvement.

![Demo of Neovim MATLAB Plugin](docs/example.gif)

## Features

### Core Features
- 🚀 Launch MATLAB console in a tmux split
- ▶️ Run MATLAB scripts and cells directly from Neovim
- 📁 Execute code cells (sections between `%%` comments)
- 🔍 Fold/unfold MATLAB cell sections
- 📚 Access MATLAB documentation for functions
- 💾 Save and load MATLAB workspace files
- 🎨 Enhanced syntax highlighting

### Debugging Features
- 🐛 Native MATLAB debugger integration (no external dependencies)
- 🔴 Visual breakpoint indicators with full-line highlighting
- ⏯️ Step-through execution (over, into, out)
- 📊 Variable inspection and workspace viewing
- 📞 Call stack visualization
- 🎛️ Interactive debug UI with floating windows
- 🔄 Efficient debug line tracking (updates on command execution)

## Requirements

- **Neovim**: 0.7.0 or later
- **tmux**: Must be installed and running
- **MATLAB**: Any recent version

### Tmux Setup

This plugin requires running Neovim inside a tmux session.

**Quick Start:**

1. **Install tmux:**
   - macOS: `brew install tmux`
   - Ubuntu/Debian: `sudo apt install tmux`
   - CentOS/RHEL: `sudo yum install tmux`

2. **Start tmux and Neovim:**
   ```bash
   tmux
   nvim
   ```

3. **Basic tmux commands:**
   - Split horizontally: `Ctrl-b "`
   - Split vertically: `Ctrl-b %`
   - Switch panes: `Ctrl-b arrow-key`
   - Detach session: `Ctrl-b d`
   - Reattach: `tmux attach`

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim) (Recommended)

```lua
{
  'idossha/matlab.nvim',
  ft = 'matlab',  -- Lazy-load on MATLAB files
  config = function()
    require('matlab').setup()
  end
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'idossha/matlab.nvim',
  config = function()
    require('matlab').setup()
  end
}
```

## Configuration

### Basic Configuration

```lua
require('matlab').setup({
  -- MATLAB executable path (auto-detected if in PATH)
  executable = 'matlab',  -- or full path: '/Applications/MATLAB_R2024a.app/bin/matlab'

  -- Tmux pane configuration
  panel_size = 50,                  -- Size in percentage
  panel_size_type = 'percentage',   -- 'percentage' or 'fixed'
  tmux_pane_direction = 'right',    -- 'right' or 'below'
  tmux_pane_focus = true,           -- Focus pane when created

  -- Behavior
  auto_start = true,                -- Auto-start MATLAB on .m files
  default_mappings = true,          -- Enable default keybindings
  minimal_notifications = true,     -- Show only important messages

  -- Prevent GUI from opening during debugging
  force_nogui_with_breakpoints = true,
})
```

### Advanced Configuration

```lua
require('matlab').setup({
  executable = '/usr/local/MATLAB/R2024a/bin/matlab',

  -- Environment variables (useful for Linux/WSL)
  environment = {
    LD_LIBRARY_PATH = '/usr/local/lib',
    -- DISPLAY = ':0',  -- Uncomment for X11 forwarding
  },

  -- Debug features
  debug_features = {
    enabled = true,
    auto_update_ui = true,
    show_debug_status = true,
  },

  -- Debug UI window positions
  debug_ui = {
    variables_position = 'right',   -- 'left', 'right', 'top', 'bottom'
    variables_size = 0.3,
    callstack_position = 'bottom',
    callstack_size = 0.3,
    breakpoints_position = 'left',
    breakpoints_size = 0.25,
  },

  -- Logging
  debug = false,  -- Enable debug logging to ~/.cache/nvim/matlab_nvim.log

  -- Custom keymappings
  mappings = {
    prefix = '<Leader>m',
    run = 'r',
    run_cell = 'c',
    run_to_cell = 't',
    doc = 'h',
    toggle_workspace = 'w',
    clear_workspace = 'x',
    save_workspace = 's',
    load_workspace = 'l',
    toggle_cell_fold = 'f',
    toggle_all_cell_folds = 'F',
    open_in_gui = 'g',
    -- Debug mappings
    debug_start = 's',
    debug_stop = 'q',
    debug_continue = 'c',
    debug_step_over = 'o',
    debug_step_into = 'i',
    debug_step_out = 't',
    debug_toggle_breakpoint = 'b',
    debug_clear_breakpoints = 'B',
    debug_eval = 'e',
    -- Debug UI mappings
    debug_ui = 'u',
    debug_ui_variables = 'v',
    debug_ui_callstack = 'k',
    debug_ui_breakpoints = 'p',
    debug_ui_repl = 'r',
    debug_ui_show_all = 'a',
    debug_ui_close = 'Q',
  }
})
```

### Finding Your MATLAB Installation

The plugin auto-detects MATLAB in standard locations. If auto-detection fails, specify the full path:

**macOS:**
```lua
executable = '/Applications/MATLAB_R2024a.app/bin/matlab'
```

**Linux:**
```lua
executable = '/usr/local/MATLAB/R2024a/bin/matlab'
```

**Windows:**
```lua
executable = 'C:\\Program Files\\MATLAB\\R2024a\\bin\\matlab.exe'
```

**To find your installation:**
- macOS: Check `/Applications/` for `MATLAB_R####x.app`
- Linux: Run `which matlab` or check `/usr/local/MATLAB/`, `/opt/MATLAB/`
- Windows: Check `C:\Program Files\MATLAB\`

## Usage

### Default Keymappings

All mappings use `<Leader>m` prefix (e.g., `<Leader>mr` to run).

#### Basic Operations

| Key | Command | Description |
|-----|---------|-------------|
| `<Leader>mr` | `:MatlabRun` | Run current script |
| `<Leader>mc` | `:MatlabRunCell` | Run current cell |
| `<Leader>mt` | `:MatlabRunToCell` | Run from start to current cell |
| `<Leader>mh` | `:MatlabDoc` | Show documentation |
| `<Leader>mg` | `:MatlabOpenInGUI` | Open in MATLAB GUI |

#### Workspace Management

| Key | Command | Description |
|-----|---------|-------------|
| `<Leader>mw` | `:MatlabWorkspace` | Show workspace variables |
| `<Leader>mx` | `:MatlabClearWorkspace` | Clear workspace |
| `<Leader>ms` | `:MatlabSaveWorkspace` | Save workspace to .mat |
| `<Leader>ml` | `:MatlabLoadWorkspace` | Load workspace from .mat |

#### Code Folding

| Key | Command | Description |
|-----|---------|-------------|
| `<Leader>mf` | `:MatlabToggleCellFold` | Toggle current cell fold |
| `<Leader>mF` | `:MatlabToggleAllCellFolds` | Toggle all cell folds |

### Working with Cells

MATLAB cells are code sections separated by `%%` comments:

```matlab
%% Cell 1: Setup
x = 1:10;

%% Cell 2: Processing
y = x.^2;

%% Cell 3: Plotting
plot(x, y);
```

- Execute current cell: `<Leader>mc`
- Execute up to current cell: `<Leader>mt`
- Fold/unfold cells: `<Leader>mf` / `<Leader>mF`

## Debugging

### Quick Start

1. Set breakpoints: `<Leader>mdb` (or `:MatlabDebugToggleBreakpoint`)
2. Start debugging: `<Leader>mds` (or `:MatlabDebugStart`)
3. Step through code:
   - `<Leader>mdc` - Continue to next breakpoint
   - `<Leader>mdo` - Step over (execute line)
   - `<Leader>mdi` - Step into (enter functions)
   - `<Leader>mdt` - Step out (exit function)
4. Stop debugging: `<Leader>mdq` (or `:MatlabDebugStop`)

### Debug Commands

| Key | Command | Description |
|-----|---------|-------------|
| `<Leader>mds` | `:MatlabDebugStart` | Start debugging session |
| `<Leader>mdq` | `:MatlabDebugStop` | Stop debugging |
| `<Leader>mdc` | `:MatlabDebugContinue` | Continue execution |
| `<Leader>mdo` | `:MatlabDebugStepOver` | Step over line |
| `<Leader>mdi` | `:MatlabDebugStepInto` | Step into function |
| `<Leader>mdt` | `:MatlabDebugStepOut` | Step out of function |
| `<Leader>mdb` | `:MatlabDebugToggleBreakpoint` | Toggle breakpoint |
| `<Leader>mdB` | `:MatlabDebugClearBreakpoints` | Clear all breakpoints |
| `<Leader>mde` | `:MatlabDebugEval` | Evaluate expression |

### Debug UI

The plugin provides VSCode/DAP-like floating windows:

| Key | Command | Description |
|-----|---------|-------------|
| `<Leader>mdu` | `:MatlabDebugUI` | Show control bar |
| `<Leader>mdv` | `:MatlabDebugUIVariables` | Show variables window |
| `<Leader>mdk` | `:MatlabDebugUICallStack` | Show call stack |
| `<Leader>mdp` | `:MatlabDebugUIBreakpoints` | Show breakpoints list |
| `<Leader>mdr` | `:MatlabDebugUIRepl` | Show interactive REPL |
| `<Leader>mda` | `:MatlabDebugUIShowAll` | Show all windows |
| `<Leader>mdQ` | `:MatlabDebugUIClose` | Close all debug UI |

#### Debug Control Bar

The control bar (`:MatlabDebugUI`) provides:

- **Status indicator**: 🔴 DEBUGGING or ⚪ STOPPED
- **F-key shortcuts**: F5=Continue, F10=Step Over, F11=Step Into, F12=Step Out
- **Quick actions**:
  - `b` - Toggle breakpoint
  - `B` - Clear all breakpoints
  - `s` - Start debugging
  - `q` - Stop debugging
- **Window management**: `v`, `c`, `p`, `r`, `a`

### Visual Indicators

- **Breakpoints**: Red circle (●) with full-line red highlighting
- **Current line**: Blue arrow (▶) with full-line highlighting
- Updates automatically when you step/continue

### How It Works

Uses MATLAB's native debugger (`dbstop`, `dbcont`, `dbstep`, etc.). No external dependencies required. All debug output appears in the MATLAB tmux pane.

### Debug Tips

- Files auto-save when starting debug session
- Breakpoints persist across sessions (same Neovim instance)
- Use MATLAB commands directly in tmux pane (`whos`, `dbstack`, etc.)
- Variables window updates after each step/continue
- Press `r` in any debug window to refresh

## Troubleshooting

### Common Issues

#### MATLAB Opens GUI Instead of CLI (Linux/WSL)

The plugin automatically unsets `DISPLAY` on Linux/WSL to force CLI mode.

If GUI still opens:
1. Enable debug logging: `debug = true` in setup
2. Check log: `~/.cache/nvim/matlab_nvim.log`
3. Verify: `/path/to/matlab -nodesktop -nosplash -nodisplay`

For X11 forwarding:
```lua
environment = {
  DISPLAY = ':0',
}
```

#### "MATLAB pane could not be found"

**Causes:**
- Not inside tmux session
- MATLAB failed to start
- Incorrect executable path

**Solutions:**
- Ensure running in tmux: `tmux` then `nvim`
- Verify executable path in config
- Try `:MatlabStartServer` manually
- Enable debug mode and check logs

#### Environment Variable Conflicts (Arch Linux, etc.)

Use `environment` config option:

```lua
-- ❌ Wrong:
executable = "export LD_LIBRARY_PATH=/path; matlab"

-- ✅ Correct:
executable = '/usr/local/MATLAB/R2024a/bin/matlab',
environment = {
  LD_LIBRARY_PATH = '/custom/path',
  XAPPLRESDIR = '/opt/matlab/X11/app-defaults',
}
```

#### Debugging Issues

**Breakpoint not stopping:**
- Ensure line has executable code (not comments/blank lines)
- File must be saved (`:w`)

**"Cannot find function":**
- Plugin auto-changes to file's directory
- Verify filename matches function name
- Ensure file is saved

**Lost track of breakpoints:**
- Use `:MatlabDebugShowBreakpoints` to list all

### Debug Mode

Enable detailed logging:

```lua
require('matlab').setup({
  debug = true,
})
```

Check configuration: `:MatlabShowConfig`
View logs: `~/.cache/nvim/matlab_nvim.log`

## Environment Variables

The `environment` option sets variables before MATLAB starts:

```lua
environment = {
  LD_LIBRARY_PATH = '/usr/local/lib',      -- Custom libraries
  DISPLAY = ':0',                          -- X11 forwarding
  MATLAB_LOG_DIR = '/tmp/matlab_logs',     -- Log directory
}
```

**Common use cases:**
- Library paths on Linux
- X11 forwarding on remote servers
- Fixing package conflicts
- Debug mode configurations

Variable names must be valid (letters, numbers, underscores). Invalid names are ignored with warnings.

## Advanced Features

### Customizing Keymaps

Change prefix or individual keys:

```lua
mappings = {
  prefix = ',',     -- Use comma instead of <Leader>m
  run = 'e',        -- Run with ,e
  run_cell = 'r',   -- Run cell with ,r
}
```

### Panel Configuration

```lua
panel_size = 40,                    -- 40% width
panel_size_type = 'percentage',     -- or 'fixed' for columns
tmux_pane_direction = 'below',      -- Pane below editor
tmux_pane_focus = false,            -- Don't auto-focus pane
```

### Minimal Notifications

```lua
minimal_notifications = true,  -- Only show important messages
```

Shows only:
- Server start/stop
- Errors
- Forced notifications

## Performance Optimizations

Recent improvements:
- Removed 2-second polling timer (saves CPU)
- Efficient debug line updates (only on commands)
- Reduced tmux capture size (75% reduction)
- Enhanced error handling (prevents crashes)
- Smart retry logic for parsing

## License

MIT

## Contributing

Contributions welcome! Please feel free to:
- Report bugs via GitHub Issues
- Submit pull requests
- Suggest features
- Improve documentation

See the [GitHub repository](https://github.com/idossha/matlab.nvim) for more information.
