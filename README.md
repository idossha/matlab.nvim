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

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'idossha/matlab.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
  },
  config = function()
    require('matlab').setup({
      -- IMPORTANT: Set the path to your MATLAB executable
      matlab_executable = '/path/to/your/matlab',
      
      -- Optional: Other configuration options
      highlight_cells = true,
      workspace = {
        position = 'right',
        width = 40,
      },
    })
  end,
  ft = 'matlab',
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'idossha/matlab.nvim',
  requires = {
    'nvim-lua/plenary.nvim',
    'MunifTanjim/nui.nvim',
  },
  config = function()
    require('matlab').setup({
      -- IMPORTANT: Set the path to your MATLAB executable
      matlab_executable = '/path/to/your/matlab',
      
      -- Optional: Other configuration options
      highlight_cells = true,
      workspace = {
        position = 'right',
        width = 40,
      },
    })
  end
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
" Required dependencies
Plug 'nvim-lua/plenary.nvim'
Plug 'MunifTanjim/nui.nvim'
Plug 'yourusername/matlab.nvim'

" In your init.vim, after plug#end():
lua << EOF
  require('matlab').setup({
    -- IMPORTANT: Set the path to your MATLAB executable
    matlab_executable = '/path/to/your/matlab',
    
    -- Optional: Other configuration options
    highlight_cells = true,
    workspace = {
      position = 'right',
      width = 40,
    },
  })
EOF
```
```

## Configuration

```lua
require('matlab').setup({
  -- MATLAB executable path (IMPORTANT: set this to your MATLAB executable path)
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

### Configuring MATLAB Executable Path

The most important configuration option is the `matlab_executable` setting, which must point to your MATLAB executable. If not properly configured, you'll see errors like:

```
Error executing lua: [...] matlab: Executable not found
```

#### Common MATLAB Executable Paths

Set the `matlab_executable` to the full path of your MATLAB installation:

**Windows:**
```lua
matlab_executable = 'C:/Program Files/MATLAB/R2023b/bin/matlab.exe',
```

**macOS:**
```lua
matlab_executable = '/Applications/MATLAB_R2023b.app/bin/matlab',
```

**Linux:**
```lua
matlab_executable = '/usr/local/MATLAB/R2023b/bin/matlab',
```

Replace `R2023b` with your actual MATLAB version.

#### Finding Your MATLAB Path

If you're unsure where MATLAB is installed:

1. **Windows**: Open Command Prompt and type `where matlab`
2. **macOS/Linux**: Open Terminal and type `which matlab`
3. Or search for the MATLAB executable in common installation directories

If MATLAB is already in your system PATH, you can leave the default setting.

#### Troubleshooting

If you still encounter "Executable not found" errors:

1. Verify MATLAB works from the command line by running `matlab -nodesktop`
2. Try using the absolute path to the MATLAB startup script or batch file
3. Ensure proper permissions to execute MATLAB from Neovim
4. Check for any special characters in the path that might need escaping
```

## Usage

- Place your cursor within a MATLAB cell and press `<leader>mc` to execute it
- Navigate between cells with `[m` and `]m`
- Toggle workspace viewer with `<leader>mw`
- Execute entire file with `<leader>mf`
- Select code and execute it with `<leader>ms`

## License

MIT
