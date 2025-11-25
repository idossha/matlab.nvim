# Quick Start Guide

Get up and running with matlab.nvim debugging in 5 minutes.

## 1. Install

Add to your lazy.nvim config:

```lua
{
  'idohaber/matlab.nvim',
  ft = 'matlab',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    dependencies = {
      'mfussenegger/nvim-dap',
      'nvim-neotest/nvim-nio'
    }
  },
  config = function()
    require('matlab').setup()
    require('dapui').setup()
  end
}
```

Restart Neovim or run `:Lazy sync`

## 2. Verify Installation

Open a MATLAB file:
```bash
tmux  # Start tmux if not already in it
nvim test.m
```

Start MATLAB:
```vim
:MatlabStartServer
```

You should see MATLAB start in a tmux pane.

## 3. Your First Debug Session

Create a simple MATLAB file:

```matlab
% test.m
function result = test()
    x = 1:10;
    y = x.^2;
    result = sum(y);
end
```

**Set a breakpoint:**
- Move cursor to line 3 (`y = x.^2;`)
- Press `<F9>`

You should see a `■` sign appear in the gutter.

**Start debugging:**
```vim
:MatlabDebugStart
```

**Open debug UI:**
```vim
:MatlabDebugUI
```

You should see:
- **Left sidebar**: Breakpoints, call stack, variables
- **Bottom panel**: MATLAB REPL

## 4. Debug Controls

| Key | Action |
|-----|--------|
| `<F5>` | Continue execution |
| `<F9>` | Toggle breakpoint |
| `<F10>` | Step over |
| `<F11>` | Step into |
| `<F12>` | Step out |

Try stepping through your code with `<F10>`.

## 5. Inspect Variables

**Option 1: Variables window**
```vim
:MatlabDebugShowVariables
```

**Option 2: REPL**
```vim
:MatlabDebugShowRepl
```

In the REPL window:
1. Press `i` to enter insert mode
2. Type `whos`
3. Press `<CR>` to execute

Check the MATLAB pane for output.

## Troubleshooting

### "MATLAB pane not available"

**Solution:** Start MATLAB first
```vim
:MatlabStartServer
```

### "nvim-dap-ui not found"

**Solution:** Install dependencies
```vim
:Lazy sync
```

Then restart Neovim.

### Debug UI doesn't appear

**Solution:** Verify nvim-dap-ui is loaded
```vim
:lua print(vim.inspect(require('dapui')))
```

If error, check your plugin configuration.

### Breakpoints don't work

**Solution:**
1. Save the file (`:w`)
2. Check MATLAB pane for errors
3. Try clearing and re-setting (`<F9>` twice)

## Next Steps

- Read **[DEBUGGING.md](DEBUGGING.md)** for complete guide
- Customize keybindings (see examples in DEBUGGING.md)
- Configure custom layouts
- Run tests: `:PlenaryBustedDirectory tests/`

## Need Help?

1. Check [DEBUGGING.md](DEBUGGING.md) - Comprehensive guide
2. Check [tests/README.md](tests/README.md) - Testing info
3. Open an issue on GitHub
4. Check existing issues for solutions

## Key Resources

| Document | Purpose |
|----------|---------|
| [DEBUGGING.md](DEBUGGING.md) | Complete debugging guide |
| [README.md](README.md) | Plugin overview and config |
| [SIMPLIFICATION_SUMMARY.md](SIMPLIFICATION_SUMMARY.md) | Recent changes |
| [tests/README.md](tests/README.md) | Testing guide |

Happy debugging! 🐛✨
