# MATLAB.nvim

A Neovim plugin for MATLAB development providing IDE-like features within your favorite editor.

## Features

- Visual rendering of MATLAB cells with separation lines
- Bolded cell titles after "%%"
- Workspace variable viewer
- Execute MATLAB code directly from Neovim
- Navigate between cells
- MATLAB-specific code completion

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
  'yourusername/matlab.nvim',
  requires = {
    'nvim-lua/plenary.nvim',  -- For utilities
    'MunifTanjim/nui.nvim',   -- For UI components
  },
  config = function()
    require('matlab').setup()
  end
}
```

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'yourusername/matlab.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
  },
  config = function()
    require('matlab').setup()
  end,
  ft = 'matlab',
}
```

## Configuration

```lua
require('matlab').setup({
  -- MATLAB executable path (default: tries to find in PATH)
  matlab_executable = 'matlab',
  
  -- Enable cell rendering
  highlight_cells = true,
  
  -- Cell separator appearance
  cell_separator = {
    -- Character to use for separator line
    char = '─',
    -- Length of the separator line (0 = full width)
    length = 0,
  },
  
  -- Workspace viewer settings
  workspace = {
    -- Enable workspace viewer
    enable = true,
    -- Position: 'right', 'left', or 'float'
    position = 'right',
    -- Width of the sidebar (when position is 'right' or 'left')
    width = 40,
    -- Auto-refresh interval in seconds (0 to disable)
    refresh_interval = 5,
  },
  
  -- Keymappings
  mappings = {
    -- Navigate to next cell
    next_cell = ']m',
    -- Navigate to previous cell
    prev_cell = '[m',
    -- Execute current cell
    exec_cell = '<leader>mc',
    -- Execute entire file
    exec_file = '<leader>mf',
    -- Execute current selection
    exec_selection = '<leader>ms',
    -- Toggle workspace viewer
    toggle_workspace = '<leader>mw',
  },
})
```

## Usage

- Place your cursor within a MATLAB cell and press `<leader>mc` to execute it
- Navigate between cells with `[m` and `]m`
- Toggle workspace viewer with `<leader>mw`
- Execute entire file with `<leader>mf`
- Select code and execute it with `<leader>ms`

## License

MIT
