# MATLAB Debugging in matlab.nvim

## Overview

matlab.nvim provides debugging support using MATLAB's native debugging commands. The plugin integrates MATLAB's debugger with Neovim through tmux.

## Architecture

- **Backend**: MATLAB's built-in debugger (`dbstop`, `dbcont`, `dbstep`, etc.)
- **Interface**: Neovim signs, commands, and debug sidebar
- **Execution**: All debug operations run in the tmux MATLAB pane

## Key Features

### Breakpoint Management
- **Visual indicators**: Red circle (●) for breakpoints, blue arrow (▶) for current line
- **Interactive toggling**: Set/clear breakpoints with `<Leader>mdb`
- **Persistence**: Breakpoints maintained within session
- **Synchronization**: Neovim breakpoints sync with MATLAB debugger

### Execution Control
- **Start/Stop**: `<Leader>mds` / `<Leader>mdq`
- **Stepping**: Step over (`<Leader>mdn`), into (`<Leader>mdi`), out (`<Leader>mdo`)
- **Continue**: Run to next breakpoint with `<Leader>mdc`
- **Global F-keys**: During debugging, F5/F10/F11/F12 work from ANY buffer

### Debug Sidebar
- **Toggle**: `:MatlabDebugUI` or `<Leader>mdu`
- **Shows**: Variables, call stack, and breakpoints
- **Navigation**: Press `<CR>` on stack frames or breakpoints to jump to location
- **Refresh**: Press `r` to refresh, `w` to update workspace

## Workflow

### Quick Start
1. Open MATLAB file in Neovim (inside tmux)
2. Start MATLAB server: `:MatlabStartServer`
3. Set breakpoints: `<Leader>mdb` on desired lines
4. Start debugging: `<Leader>mds` or `F5`
5. Step through code: `F10` (over) / `F11` (into) / `F12` (out)
6. Inspect state via debug sidebar: `<Leader>mdu`
7. Stop debugging: `Shift+F5` or `<Leader>mdq`

### Conditional Breakpoints

Use MATLAB's native commands directly in the tmux pane:

```matlab
dbstop in myfile at 22 if x > 5
dbstop in myfile at 33 if strcmp(status, 'error')
```

## Commands & Mappings

### Debug Commands (`<Leader>md` + key)
| Mapping | Command | Description |
|---------|---------|-------------|
| `<Leader>mds` | `:MatlabDebugStart` | Start debugging session |
| `<Leader>mdq` | `:MatlabDebugStop` | Stop debugging session |
| `<Leader>mdc` | `:MatlabDebugContinue` | Continue to next breakpoint |
| `<Leader>mdn` | `:MatlabDebugStepOver` | Step over (next line) |
| `<Leader>mdi` | `:MatlabDebugStepInto` | Step into function |
| `<Leader>mdo` | `:MatlabDebugStepOut` | Step out of function |
| `<Leader>mdb` | `:MatlabDebugToggleBreakpoint` | Toggle breakpoint |
| `<Leader>mdB` | `:MatlabDebugClearBreakpoints` | Clear all breakpoints |
| `<Leader>mde` | `:MatlabDebugEval` | Evaluate expression |
| `<Leader>mdu` | `:MatlabDebugUI` | Toggle debug sidebar |

### Global F-Keys (Active During Debug Session)
| Key | Action |
|-----|--------|
| `F5` | Continue (or Start) |
| `F10` | Step Over |
| `F11` | Step Into |
| `F12` | Step Out |
| `Shift+F5` | Stop Debug |

### Debug Sidebar Keybindings
| Key | Action |
|-----|--------|
| `q` | Close sidebar |
| `r` | Refresh display |
| `w` | Update workspace from MATLAB |
| `<CR>` | Jump to location under cursor |

## MATLAB Commands Used

The plugin sends these commands to MATLAB:

- `dbstop in file at line` - Set breakpoint
- `dbclear file at line` - Clear specific breakpoint
- `dbclear all` - Clear all breakpoints
- `dbcont` - Continue execution
- `dbstep` - Step over
- `dbstep in` - Step into function
- `dbstep out` - Step out of function
- `dbstack` - Show call stack
- `dbstatus` - Show all breakpoints
- `dbquit` - Exit debug mode
- `whos` - Show workspace variables

## Limitations

- No conditional breakpoints via UI (use MATLAB commands directly)
- No watch expressions
- Requires tmux environment

## Troubleshooting

**Breakpoints not working**: Ensure line contains executable code (not comments/empty)
**Commands fail**: Verify MATLAB server is running (`:MatlabStartServer`)
**Debug line not updating**: Run `:MatlabDebugUpdateLine` to manually refresh
