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

### MATLAB Executable Detection

The plugin will automatically attempt to find your MATLAB installation by searching common installation paths based on your operating system. If found, it will use that installation for the current session and suggest updating your configuration.

However, if you're getting the error "Something went wrong starting the MATLAB server", it's best to explicitly specify the full path to your MATLAB executable:

**For macOS:**
```lua
require('matlab').setup({
  executable = '/Applications/MATLAB_R2024a.app/bin/matlab',  -- Adjust according to your version
  -- other options...
})
```

**For Linux:**
```lua
require('matlab').setup({
  executable = '/usr/local/MATLAB/R2024a/bin/matlab',  -- Adjust according to your installation
  -- other options...
})
```

**For Windows:**
```lua
require('matlab').setup({
  executable = 'C:\\Program Files\\MATLAB\\R2024a\\bin\\matlab.exe',  -- Adjust according to your installation
  -- other options...
})
```

#### Finding Your MATLAB Path

If you're not sure where MATLAB is installed:

**macOS**:
1. Open Finder
2. Navigate to Applications folder
3. Look for "MATLAB_R####x.app" (where #### is the year and x is a or b)
4. The executable is located at `/Applications/MATLAB_R####x.app/bin/matlab`

**Linux**:
1. Run `which matlab` in your terminal to see if it's in your PATH
2. Common installation directories include:
   - `/usr/local/MATLAB/R####x/bin/matlab`
   - `/opt/MATLAB/R####x/bin/matlab`
   - `~/MATLAB/R####x/bin/matlab`

**Windows**:
1. Check Program Files folder: `C:\Program Files\MATLAB\R####x\bin\matlab.exe`
2. Or for 32-bit MATLAB on 64-bit Windows: `C:\Program Files (x86)\MATLAB\R####x\bin\matlab.exe`

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
