# MATLAB Debugging Guide

matlab.nvim provides simple, native MATLAB debugging support with no external dependencies.

## Overview

The debugging module uses MATLAB's built-in debugging commands (`dbstop`, `dbcont`, `dbstep`, etc.) and displays breakpoints using Neovim signs. All debug output appears in your MATLAB tmux pane.

## Quick Start

1. Set breakpoints in your MATLAB file with `:MatlabDebugToggleBreakpoint` or `<Leader>mdb`
2. Start debugging with `:MatlabDebugStart` or `<Leader>mds`
3. Use stepping commands to navigate through your code
4. View variables, stack, and breakpoints in the MATLAB pane

## Commands

### Core Debug Commands

- `:MatlabDebugStart` - Start debugging the current file
- `:MatlabDebugStop` - Stop the current debugging session
- `:MatlabDebugContinue` - Continue execution until next breakpoint
- `:MatlabDebugStepOver` - Execute current line and move to next
- `:MatlabDebugStepInto` - Step into function calls
- `:MatlabDebugStepOut` - Step out of current function

### Breakpoint Commands

- `:MatlabDebugToggleBreakpoint` - Toggle breakpoint at current line
- `:MatlabDebugClearBreakpoints` - Clear all breakpoints

### Inspection Commands

- `:MatlabDebugShowVariables` - Show workspace variables (`whos`)
- `:MatlabDebugShowStack` - Show call stack (`dbstack`)
- `:MatlabDebugShowBreakpoints` - Show all breakpoints (`dbstatus`)
- `:MatlabDebugEval` - Evaluate an expression in debug context

## Default Key Mappings

With the default `<Leader>m` prefix:

- `<Leader>mds` - Start debugging
- `<Leader>mde` - Stop debugging
- `<Leader>mdc` - Continue
- `<Leader>mdo` - Step over
- `<Leader>mdi` - Step into
- `<Leader>mdt` - Step out
- `<Leader>mdb` - Toggle breakpoint
- `<Leader>mdd` - Clear all breakpoints
- `<Leader>mdv` - Show variables
- `<Leader>mdk` - Show stack
- `<Leader>mdp` - Show breakpoints
- `<Leader>mdx` - Evaluate expression

## Typical Workflow

1. **Set Breakpoints**: Navigate to the lines where you want to pause and press `<Leader>mdb`
   - Breakpoints are shown with a red circle (●) in the sign column

2. **Start Debug Session**: Press `<Leader>mds` or run `:MatlabDebugStart`
   - Your file will be saved automatically
   - MATLAB will run the file and stop at the first breakpoint

3. **Inspect State**:
   - Press `<Leader>mdv` to see all variables (`whos`)
   - Press `<Leader>mdk` to see the call stack (`dbstack`)
   - Press `<Leader>mdx` to evaluate expressions

4. **Navigate Code**:
   - Press `<Leader>mdo` to step over lines
   - Press `<Leader>mdi` to step into function calls
   - Press `<Leader>mdt` to step out of the current function
   - Press `<Leader>mdc` to continue to the next breakpoint

5. **Stop Debugging**: Press `<Leader>mde` when done

## Visual Indicators

- **Red circle (●)**: Active breakpoint at this line
- Debug output and variable inspection appear in the MATLAB tmux pane

## Notes

- Breakpoints persist across debug sessions
- All breakpoints are synchronized with MATLAB's native debugger
- The MATLAB pane shows all debug output (`whos`, `dbstack`, etc.)
- You can still run MATLAB commands directly in the tmux pane during debugging

## Troubleshooting

**Breakpoint not stopping**: Make sure the line contains executable code (not comments or blank lines)

**Can't start debugging**: Ensure MATLAB server is running (`:MatlabStartServer`)

**Lost track of breakpoints**: Use `:MatlabDebugShowBreakpoints` to see all active breakpoints in MATLAB

## Customization

### Custom Key Mappings

```lua
require('matlab').setup({
  mappings = {
    debug_start = 'ds',
    debug_stop = 'de',
    debug_continue = 'dc',
    debug_step_over = 'do',
    debug_step_into = 'di',
    debug_step_out = 'dt',
    debug_toggle_breakpoint = 'db',
    debug_clear_breakpoints = 'dd',
    debug_show_variables = 'dv',
    debug_show_stack = 'dk',
    debug_show_breakpoints = 'dp',
    debug_eval = 'dx',
  }
})
```

### Custom Breakpoint Signs

Breakpoint signs are configured in your `setup()` call:

```lua
require('matlab').setup({
  breakpoint = {
    sign_text = '●',           -- Character shown in sign column
    sign_hl = 'MatlabBreakpoint',     -- Highlight group for sign text
    line_hl = 'MatlabBreakpointLine', -- Highlight group for entire line
    num_hl = 'MatlabBreakpoint'       -- Highlight group for line number
  }
})
```

Default highlights:
- `MatlabBreakpoint`: Bold red text on dark red background
- `MatlabBreakpointLine`: Dark red line background

You can override these in your colorscheme or init.lua:

```lua
vim.api.nvim_set_hl(0, 'MatlabBreakpoint', { fg = '#ff0000', bg = '#5a0000', bold = true })
vim.api.nvim_set_hl(0, 'MatlabBreakpointLine', { bg = '#300000' })
```

## MATLAB Debug Commands Reference

The debugging module uses these native MATLAB commands:

- `dbstop in <file> at <line>` - Set breakpoint
- `dbclear <file> at <line>` - Clear specific breakpoint
- `dbclear all` - Clear all breakpoints
- `dbcont` - Continue execution
- `dbstep` - Step to next line
- `dbstep in` - Step into function
- `dbstep out` - Step out of function
- `dbstack` - Show call stack
- `dbstatus` - Show all breakpoints
- `dbquit` - Exit debug mode
- `whos` - Show workspace variables
