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

### Debug UI
- **Control Bar**: `:MatlabDebugUI` - Visual control panel with keybindings
- **Variables Window**: `:MatlabDebugUIVariables` - Floating variables display
- **Call Stack Window**: `:MatlabDebugUICallStack` - Stack trace viewer
- **Breakpoints Window**: `:MatlabDebugUIBreakpoints` - Breakpoints list
- **REPL Window**: `:MatlabDebugUIRepl` - Interactive command input

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

### Debug Commands
| Command | Default Mapping | Description |
|---------|-----------------|-------------|
| `:MatlabDebugStart` | `<Leader>mds` / `F5` | Start debugging session |
| `:MatlabDebugStop` | `<Leader>mde` / `Shift+F5` | Stop debugging session |
| `:MatlabDebugContinue` | `<Leader>mdc` / `F5` | Continue to next breakpoint |
| `:MatlabDebugStepOver` | `<Leader>mdo` / `F10` | Step over (execute line) |
| `:MatlabDebugStepInto` | `<Leader>mdi` / `F11` | Step into function |
| `:MatlabDebugStepOut` | `<Leader>mdt` / `F12` | Step out of function |
| `:MatlabDebugToggleBreakpoint` | `<Leader>mdb` | Toggle breakpoint at cursor |
| `:MatlabDebugClearBreakpoints` | `<Leader>mdd` | Clear all breakpoints |
| `:MatlabDebugEval` | `<Leader>mdx` | Evaluate expression |

### Debug UI Commands
| Command | Default Mapping | Description |
|---------|-----------------|-------------|
| `:MatlabDebugUI` | `<Leader>mdu` | Show debug control bar |
| `:MatlabDebugUIVariables` | `<Leader>mdv` | Show variables window |
| `:MatlabDebugUICallStack` | `<Leader>mdk` | Show call stack window |
| `:MatlabDebugUIBreakpoints` | `<Leader>mdp` | Show breakpoints window |
| `:MatlabDebugUIRepl` | `<Leader>mdr` | Show REPL window |
| `:MatlabDebugUIShowAll` | `<Leader>mda` | Show all debug windows |
| `:MatlabDebugUIClose` | `<Leader>mdQ` | Close all debug UI |

### Workspace Pane
| Command | Description |
|---------|-------------|
| `:MatlabToggleWorkspacePane` | Toggle live workspace viewer tmux pane |
| `:MatlabOpenWorkspacePane` | Open workspace viewer pane |
| `:MatlabCloseWorkspacePane` | Close workspace viewer pane |

### Global F-Keys (Active During Debug Session)
| Key | Action |
|-----|--------|
| `F5` | Continue (or Start if not debugging) |
| `F10` | Step Over |
| `F11` | Step Into |
| `F12` | Step Out |
| `Shift+F5` | Stop Debugging |

**Note**: F-keys work from ANY buffer during an active debug session - no need to focus the debug bar!

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
