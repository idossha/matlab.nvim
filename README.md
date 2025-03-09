# matlab.nvim

A modern Neovim plugin for MATLAB integration with tmux. This plugin provides enhanced integration between Neovim, MATLAB, and tmux, making your MATLAB development workflow more efficient.

![MATLAB.nvim Demo](https://raw.githubusercontent.com/wiki/idossha/matlab.nvim/images/demo.gif)

## Features

- Automatically launches a MATLAB console in a tmux split
- Run MATLAB scripts directly from Neovim
- Execute MATLAB code cells (sections between %% comments)
- Fold/unfold MATLAB cell sections
- Set and clear breakpoints
- Access MATLAB documentation
- View MATLAB workspace in a floating window
- Enhanced syntax highlighting with bold cell headers

## Requirements

- Neovim 0.7.0 or later
- tmux (must be installed and you must run Neovim inside a tmux session)
- MATLAB

### Tmux Setup

This plugin requires you to run Neovim inside a tmux session. If you're not familiar with tmux, here's a quick start:

1. Install tmux:
   - macOS: `brew install tmux`
   - Ubuntu/Debian: `sudo apt install tmux`
   - CentOS/RHEL: `sudo yum install tmux`

2. Start a tmux session:
   ```sh
   tmux
   ```

3. Inside the tmux session, launch Neovim:
   ```sh
   nvim
   ```

4. Basic tmux commands:
   - Split horizontally: `Ctrl-b "` 
   - Split vertically: `Ctrl-b %`
   - Switch panes: `Ctrl-b arrow-key`
   - Detach session (without closing): `Ctrl-b d`
   - Reattach to session: `tmux attach`

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
  -- Path to MATLAB executable (can be full path)
  executable = 'matlab',            
  
  -- UI options
  panel_size = 50,                  -- Size of the tmux pane (in percentage)
  panel_size_type = 'percentage',   -- 'percentage' or 'fixed' (fixed = columns)
  tmux_pane_direction = 'right',    -- Position of the tmux pane ('right', 'below')
  tmux_pane_focus = true,           -- Make tmux pane visible when created
  
  -- Behavior options
  auto_start = true,                -- Auto-start MATLAB when opening a .m file
  default_mappings = true,          -- Enable default keymappings
  
  -- Notification options
  minimal_notifications = false,    -- Only show important notifications
  debug = false,                    -- Enable debug logging
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

### Quick Start for New Users

1. Make sure you have tmux installed and are running Neovim inside a tmux session
2. Install the plugin using your preferred package manager
3. Configure the plugin with your MATLAB executable path:
   ```lua
   require('matlab').setup({
     executable = '/path/to/your/matlab',  -- Set this to your actual MATLAB path
     minimal_notifications = true,         -- Reduce notification noise
   })
   ```
4. Open any MATLAB file (.m) in Neovim - a MATLAB console will appear in a tmux pane
5. Use the following key mappings:
   - `<Leader>r` to run the entire file
   - `<Leader>rc` to run just the current cell (section between %% markers)
   - `za` to fold/unfold the current cell
   - `<Leader>w` to toggle the workspace viewer

### Common Tasks

- **Running Code**: 
  - Open any MATLAB file (.m) with Neovim inside tmux
  - Use `:MatlabRun` to execute the current file
  - Use `:MatlabRunCell` to execute the current cell (code section between %% markers)

- **Working with Cells**:
  - MATLAB cells are sections of code separated by `%%` comment lines
  - Use `za` to fold/unfold the current cell
  - Use `zA` to fold/unfold all cells
  - Use `:MatlabRunCell` to execute only the current cell

- **Debugging**:
  - Use `:MatlabBreakpoint` to set a breakpoint at the current line
  - Use `:MatlabClearBreakpoint` to clear a breakpoint
  - Run your code with `:MatlabRun` to hit the breakpoints

- **Documentation**:
  - Place cursor on any MATLAB function
  - Use `:MatlabDoc` to display documentation for it

- **Workspace Management**:
  - Use `:MatlabToggleWorkspace` to view variables in a side panel
  - Press `r` in the workspace window to refresh variables
  - Use `:MatlabClearWorkspace` to clear all variables

## Default Keymappings

When `default_mappings` is enabled, the following keymaps are available in MATLAB files:

| Mapping      | Command                  | Description                            |
|--------------|--------------------------|----------------------------------------|
| `<Leader>r`  | `:MatlabRun`             | Run current MATLAB script              |
| `<Leader>rc` | `:MatlabRunCell`         | Run current MATLAB cell                |
| `<Leader>rt` | `:MatlabRunToCell`       | Run up to current MATLAB cell          |
| `<Leader>s`  | `:MatlabBreakpoint`      | Set breakpoint at current line         |
| `<Leader>c`  | `:MatlabClearBreakpoint` | Clear breakpoint in current file       |
| `<Leader>C`  | `:MatlabClearBreakpoints`| Clear all breakpoints                  |
| `<Leader>d`  | `:MatlabDoc`             | Show documentation for word under cursor |
| `<Leader>w`  | `:MatlabToggleWorkspace` | Toggle workspace floating window       |
| `<Leader>ww` | `:MatlabWorkspace`       | Show MATLAB workspace in tmux pane     |
| `<Leader>wc` | `:MatlabClearWorkspace`  | Clear MATLAB workspace                 |
| `<Leader>ws` | `:MatlabSaveWorkspace`   | Save MATLAB workspace                  |
| `<Leader>wl` | `:MatlabLoadWorkspace`   | Load MATLAB workspace                  |
| `za`         | `:MatlabToggleCellFold`  | Toggle current cell fold               |
| `zA`         | `:MatlabToggleAllCellFolds` | Toggle all cell folds               |

## Commands

| Command                     | Description                              |
|-----------------------------|------------------------------------------|
| `:MatlabRun [command]`      | Run current file or specified command    |
| `:MatlabRunCell`            | Run current cell                         |
| `:MatlabRunToCell`          | Run code from start to current cell      |
| `:MatlabBreakpoint`         | Set breakpoint at current line           |
| `:MatlabClearBreakpoint`    | Clear breakpoint in current file         |
| `:MatlabClearBreakpoints`   | Clear all breakpoints                    |
| `:MatlabDoc`                | Show documentation for word under cursor |
| `:MatlabStartServer`        | Start MATLAB server                      |
| `:MatlabStopServer`         | Stop MATLAB server                       |
| `:MatlabToggleWorkspace`    | Toggle workspace floating window         |
| `:MatlabWorkspace`          | Show MATLAB workspace in tmux pane       |
| `:MatlabClearWorkspace`     | Clear MATLAB workspace                   |
| `:MatlabSaveWorkspace`      | Save MATLAB workspace                    |
| `:MatlabLoadWorkspace`      | Load MATLAB workspace                    |
| `:MatlabToggleCellFold`     | Toggle current cell fold                 |
| `:MatlabToggleAllCellFolds` | Toggle all cell folds                    |

## License

MIT

## Acknowledgments

This plugin is inspired by [MortenStabenau/matlab-vim](https://github.com/MortenStabenau/matlab-vim) but rewritten in Lua for Neovim with a modular architecture and enhanced functionality.
