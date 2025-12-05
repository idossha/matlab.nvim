# MATLAB Debugging in matlab.nvim

## Overview

matlab.nvim provides **basic debugging support** using MATLAB's native debugging commands. The plugin integrates MATLAB's debugger with Neovim's interface through tmux, offering breakpoint management and step-through execution without external dependencies.

## Architecture

- **Backend**: Uses MATLAB's built-in debugger (`dbstop`, `dbcont`, `dbstep`, etc.)
- **Interface**: Neovim signs, commands, and debug UI windows
- **Execution**: All debug operations run in the tmux MATLAB pane
- **No Dependencies**: Pure MATLAB commands, no external debuggers required

## Key Features

### Breakpoint Management
- **Visual indicators**: Red circle (●) for breakpoints, blue arrow (▶) for current line
- **Interactive toggling**: Set/clear breakpoints with `<Leader>mdb`
- **Persistence**: Breakpoints maintained across sessions
- **Synchronization**: Neovim breakpoints sync with MATLAB debugger

### Execution Control
- **Start/Stop**: Full session control with `<Leader>mds` / `<Leader>mde`
- **Stepping**: Step over (`<Leader>mdo`), into (`<Leader>mdi`), out (`<Leader>mdt`)
- **Continue**: Run to next breakpoint with `<Leader>mdc`
- **Global F-keys**: During debugging, F5/F10/F11/F12 work from ANY buffer

### Inspection
- **Variables**: Show workspace with `<Leader>mdv` (executes `whos`)
- **Call Stack**: Display stack with `<Leader>mdk` (executes `dbstack`)
- **Breakpoints**: List all with `<Leader>mdp` (executes `dbstatus`)
- **Evaluation**: Execute expressions with `<Leader>mdx`
- **Workspace Pane**: Live-updating workspace view: `:MatlabToggleWorkspacePane`

### Debug Sidebar
- **Toggle Sidebar**: `:MatlabDebugUI` - Unified sidebar showing variables, call stack, and breakpoints
- **Event-driven**: Updates automatically on debug actions (step, continue, breakpoint changes)
- **Navigation**: Press `<CR>` on stack frames or breakpoints to jump to location

## Workflow

### Quick Start
1. Open MATLAB file in Neovim (inside tmux)
2. Start MATLAB server: `:MatlabStartServer`
3. Set breakpoints: `<Leader>mdb` on desired lines
4. Start debugging: `<Leader>mds` or `F5`
5. Step through code: `F10` (over) / `F11` (into) / `F12` (out)
6. Inspect state: `<Leader>mdv` / `<Leader>mdk` or use `:MatlabDebugUIShowAll`
7. Stop debugging: `Shift+F5` or `<Leader>mde`

### Conditional Breakpoints

For conditional breakpoints, use MATLAB's native commands directly in the tmux pane:

```matlab
dbstop in filename at lineno if condition
```

**Examples:**
```matlab
dbstop in myfile at 22 if x > 5
dbstop in myfile at 33 if strcmp(status, 'error')
dbstop in myfile at 44 if length(data) > 10
```

This gives you full access to MATLAB's conditional breakpoint syntax without plugin complexity.

### Debug Session Lifecycle
```
Start Server → Set Breakpoints → Start Debug → Step/Continue → Inspect → Stop Debug
     ↓              ↓                    ↓              ↓            ↓         ↓
:MatlabStartServer  <Leader>mdb       <Leader>mds    <Leader>mdc   <Leader>mdv :MatlabDebugStop
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

### Workspace Commands (`<Leader>m` + key)
| Mapping | Command | Description |
|---------|---------|-------------|
| `<Leader>mw` | `:MatlabWorkspace` | Show workspace |
| `<Leader>mW` | `:MatlabRefreshWorkspace` | Refresh workspace (whos) |

### Debug Sidebar Keybindings
| Key | Action |
|-----|--------|
| `r` | Refresh content |
| `q` | Close sidebar |
| `<CR>` | Jump to location |

### Global F-Keys (Active During Debug Session)
| Key | Action |
|-----|--------|
| `F5` | Continue (or Start) |
| `F10` | Step Over |
| `F11` | Step Into |
| `F12` | Step Out |
| `Shift+F5` | Stop Debug |

**Note**: F-keys work from ANY buffer during an active debug session!

## MATLAB Commands Used

The plugin translates Neovim commands to these MATLAB debugging commands:

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

## Implementation Notes

- **File Management**: Automatically saves modified files before debugging
- **Directory Handling**: Changes MATLAB working directory to file location
- **State Synchronization**: Breakpoints persist between Neovim and MATLAB
- **Error Handling**: Validates MATLAB pane existence and debug state
- **No GUI Dependency**: Works in CLI mode, prevents GUI opening during debugging

## Limitations

- No conditional breakpoints via UI (use MATLAB commands directly - see above)
- No watch expressions
- No advanced debugging features (memory inspection, performance profiling)
- Requires tmux environment

## Troubleshooting

**Breakpoints not working**: Ensure line contains executable code (not comments/empty)
**Commands fail**: Verify MATLAB server is running (`:MatlabStartServer`)
**No output**: Check tmux MATLAB pane for debug information
**Lost breakpoints**: Use `:MatlabDebugUIBreakpoints` to verify MATLAB state
**Debug line not updating**: Run `:MatlabDebugUpdateLine` to manually refresh
**Figures not showing**: Ensure `DISPLAY` is set in your config's `environment` table
