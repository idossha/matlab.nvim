# matlab.nvim

A modern Neovim plugin for MATLAB integration with tmux. This plugin provides enhanced integration between Neovim, MATLAB, and tmux, making your MATLAB development workflow more efficient.

## Features

- Automatically launches a MATLAB console in a tmux split
- Run MATLAB scripts directly from Neovim
- Execute MATLAB code cells (sections between %% comments)
- Set and clear breakpoints
- Access MATLAB documentation
- Manage MATLAB workspace
- Enhanced syntax highlighting

## Requirements

- Neovim 0.7.0 or later
- tmux
- MATLAB

## Installation

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'idossha/matlab.nvim',
  config = function()
    require('matlab').setup()
  end
}
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'idossha/matlab.nvim',
  config = function()
    require('matlab').setup()
  end
}
```

## Configuration

You can customize matlab.nvim by passing options to the setup function:

```lua
require('matlab').setup({
  executable = 'matlab',        -- Path to MATLAB executable (can be full path like '/Applications/MATLAB_R2023b.app/bin/matlab')
  panel_size = 120,             -- Size of the tmux split
  auto_start = true,            -- Auto-start MATLAB when opening a .m file
  default_mappings = true,      -- Enable default keymappings
  debug = false,                -- Enable debug logging
})
```

### Important Note About MATLAB Path

If you're getting the error "Something went wrong starting the MATLAB server", it likely means the plugin can't find your MATLAB executable. You should specify the full path to your MATLAB executable:

For macOS:
```lua
require('matlab').setup({
  executable = '/Applications/MATLAB_R2023b.app/bin/matlab',  -- Adjust according to your version
  -- other options...
})
```

For Linux:
```lua
require('matlab').setup({
  executable = '/usr/local/MATLAB/R2023b/bin/matlab',  -- Adjust according to your installation
  -- other options...
})
```

For Windows:
```lua
require('matlab').setup({
  executable = 'C:\\Program Files\\MATLAB\\R2023b\\bin\\matlab.exe',  -- Adjust according to your installation
  -- other options...
})
```

## Usage

- Open any MATLAB file (.m) with Neovim inside tmux. A MATLAB console will automatically open inside a hidden tmux split.
- Use `:MatlabRun` to execute the current file
- Use `:MatlabRunCell` to execute the current cell (code section between %% markers)
- Use `:MatlabBreakpoint` to set a breakpoint at the current line
- Use `:MatlabDoc` to display documentation for the function under the cursor
- Use `:MatlabWorkspace` to see variables in the MATLAB workspace

## Default Keymappings

When `default_mappings` is enabled, the following keymaps are available in MATLAB files:

| Mapping    | Command                 | Description                           |
|------------|-------------------------|---------------------------------------|
| `<Leader>r`  | `:MatlabRun`            | Run current MATLAB script             |
| `<Leader>rc` | `:MatlabRunCell`        | Run current MATLAB cell               |
| `<Leader>rt` | `:MatlabRunToCell`      | Run up to current MATLAB cell         |
| `<Leader>s`  | `:MatlabBreakpoint`     | Set breakpoint at current line        |
| `<Leader>c`  | `:MatlabClearBreakpoint`| Clear breakpoint in current file      |
| `<Leader>C`  | `:MatlabClearBreakpoints`| Clear all breakpoints                |
| `<Leader>d`  | `:MatlabDoc`            | Show documentation for word under cursor |
| `<Leader>w`  | `:MatlabWorkspace`      | Show MATLAB workspace                 |
| `<Leader>wc` | `:MatlabClearWorkspace` | Clear MATLAB workspace                |
| `<Leader>ws` | `:MatlabSaveWorkspace`  | Save MATLAB workspace                 |
| `<Leader>wl` | `:MatlabLoadWorkspace`  | Load MATLAB workspace                 |

## Commands

| Command                  | Description                              |
|--------------------------|------------------------------------------|
| `:MatlabRun [command]`   | Run current file or specified command    |
| `:MatlabRunCell`         | Run current cell                         |
| `:MatlabRunToCell`       | Run code from start to current cell      |
| `:MatlabBreakpoint`      | Set breakpoint at current line           |
| `:MatlabClearBreakpoint` | Clear breakpoint in current file         |
| `:MatlabClearBreakpoints`| Clear all breakpoints                    |
| `:MatlabDoc`             | Show documentation for word under cursor |
| `:MatlabStartServer`     | Start MATLAB server                      |
| `:MatlabStopServer`      | Stop MATLAB server                       |
| `:MatlabWorkspace`       | Show MATLAB workspace                    |
| `:MatlabClearWorkspace`  | Clear MATLAB workspace                   |
| `:MatlabSaveWorkspace`   | Save MATLAB workspace                    |
| `:MatlabLoadWorkspace`   | Load MATLAB workspace                    |

## License

MIT

## Acknowledgments

This plugin is inspired by [MortenStabenau/matlab-vim](https://github.com/MortenStabenau/matlab-vim) but rewritten in Lua for Neovim with a modular architecture and enhanced functionality.
