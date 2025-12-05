# matlab.nvim

A modern Neovim plugin for MATLAB integration with tmux.

Inspired by [MortenStabenau/matlab-vim](https://github.com/MortenStabenau/matlab-vim), rewritten in Lua for Neovim.

**Contributions are welcome!**

![Demo of Neovim MATLAB Plugin](docs/example.gif)

## Features

- 🚀 Launch MATLAB console in a tmux split
- ▶️ Run MATLAB scripts and cells directly from Neovim
- 📁 Execute code cells (sections between `%%` comments)
- 🔍 Fold/unfold MATLAB cell sections
- 📚 Access MATLAB documentation for functions
- 💾 Save and load MATLAB workspace files
- 🐛 Native MATLAB debugger integration
- 🔴 Visual breakpoint indicators
- ⏯️ Step-through execution (over, into, out)
- 📊 Debug sidebar with variables, call stack, breakpoints

## Requirements

- **Neovim**: 0.7.0 or later
- **tmux**: Must be installed and running
- **MATLAB**: Any recent version

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'idossha/matlab.nvim',
  ft = 'matlab',
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

```lua
require('matlab').setup({
  -- MATLAB executable path (auto-detected if in PATH)
  executable = 'matlab',

  -- Tmux pane configuration
  panel_size = 50,
  panel_size_type = 'percentage',
  tmux_pane_direction = 'right',
  tmux_pane_focus = true,

  -- Behavior
  auto_start = true,
  default_mappings = true,
  minimal_notifications = true,

  -- Environment variables (useful for Linux)
  environment = {
    -- LD_LIBRARY_PATH = '/usr/local/lib',
    -- DISPLAY = ':0',
  },

  -- Debug logging
  debug = false,
})
```

## Usage

All mappings use `<Leader>m` prefix. Run `:MatlabKeymaps` to see all mappings.

### Basic Operations

| Key | Command | Description |
|-----|---------|-------------|
| `<Leader>mr` | `:MatlabRun` | Run current script |
| `<Leader>mc` | `:MatlabRunCell` | Run current cell |
| `<Leader>mC` | `:MatlabRunToCell` | Run from start to current cell |
| `<Leader>mh` | `:MatlabDoc` | Show documentation |
| `<Leader>mg` | `:MatlabOpenInGUI` | Open in MATLAB GUI |

### Workspace Management

| Key | Command | Description |
|-----|---------|-------------|
| `<Leader>mw` | `:MatlabWorkspace` | Show workspace variables |
| `<Leader>mx` | `:MatlabClearWorkspace` | Clear workspace |

### Code Folding

| Key | Command | Description |
|-----|---------|-------------|
| `<Leader>mf` | `:MatlabToggleCellFold` | Toggle current cell fold |

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

## Debugging

### Quick Start

1. Set breakpoints: `<Leader>mdb`
2. Start debugging: `<Leader>mds` (or `F5`)
3. Step through code:
   - `<Leader>mdc` or `F5` - Continue to next breakpoint
   - `<Leader>mdn` or `F10` - Step over
   - `<Leader>mdi` or `F11` - Step into
   - `<Leader>mdo` or `F12` - Step out
4. Stop debugging: `<Leader>mdq` (or `Shift+F5`)

### Debug Commands

| Key | Command | Description |
|-----|---------|-------------|
| `<Leader>mds` | `:MatlabDebugStart` | Start debugging |
| `<Leader>mdq` | `:MatlabDebugStop` | Stop debugging |
| `<Leader>mdc` | `:MatlabDebugContinue` | Continue execution |
| `<Leader>mdn` | `:MatlabDebugStepOver` | Step over line |
| `<Leader>mdi` | `:MatlabDebugStepInto` | Step into function |
| `<Leader>mdo` | `:MatlabDebugStepOut` | Step out of function |
| `<Leader>mdb` | `:MatlabDebugToggleBreakpoint` | Toggle breakpoint |
| `<Leader>mdB` | `:MatlabDebugClearBreakpoints` | Clear all breakpoints |
| `<Leader>mde` | `:MatlabDebugEval` | Evaluate expression |
| `<Leader>mdu` | `:MatlabDebugUI` | Toggle debug sidebar |

### Visual Indicators

- **Breakpoints**: Red circle (●) with full-line highlighting
- **Current line**: Blue arrow (▶) with full-line highlighting

### Debug Tips

- Files auto-save when starting debug session
- Breakpoints persist within Neovim session
- Use MATLAB commands directly in tmux pane (`whos`, `dbstack`, etc.)
- Press `r` in debug sidebar to refresh, `w` to update workspace

## Troubleshooting

### "MATLAB pane could not be found"

- Ensure running in tmux: `tmux` then `nvim`
- Verify executable path in config
- Try `:MatlabStartServer` manually

### Debugging Issues

**Breakpoint not stopping:**
- Ensure line has executable code (not comments/blank lines)
- File must be saved (`:w`)

### Debug Mode

Enable detailed logging:

```lua
require('matlab').setup({
  debug = true,
})
```

Check configuration: `:MatlabShowConfig`
View logs: `~/.cache/nvim/matlab_nvim.log`

## License

MIT
