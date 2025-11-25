# MATLAB Debugging in matlab.nvim

## Overview

matlab.nvim provides **basic debugging support** using MATLAB's native debugging commands. The plugin integrates MATLAB's debugger with Neovim's interface through tmux, offering breakpoint management and step-through execution without external dependencies.

## Architecture

- **Backend**: Uses MATLAB's built-in debugger (`dbstop`, `dbcont`, `dbstep`, etc.)
- **Interface**: Neovim signs and commands
- **Execution**: All debug operations run in the tmux MATLAB pane
- **No Dependencies**: Pure MATLAB commands, no external debuggers required

## Key Features

### Breakpoint Management
- **Visual indicators**: Red circle (●) for regular breakpoints, diamond (◆) for conditional breakpoints
- **Interactive toggling**: Set/clear breakpoints with `<Leader>mdb`
- **Conditional breakpoints**: Set conditions when creating breakpoints (e.g., `x > 5`)
- **Edit conditions**: Modify breakpoint conditions with `<Leader>mde`
- **Persistence**: Breakpoints and conditions maintained across sessions
- **Synchronization**: Neovim breakpoints sync with MATLAB debugger

### Execution Control
- **Start/Stop**: Full session control with `<Leader>mds` / `<Leader>mde`
- **Stepping**: Step over (`<Leader>mdo`), into (`<Leader>mdi`), out (`<Leader>mdt`)
- **Continue**: Run to next breakpoint with `<Leader>mdc`

### Inspection
- **Variables**: Show workspace with `<Leader>mdv` (executes `whos`)
- **Call Stack**: Display stack with `<Leader>mdk` (executes `dbstack`)
- **Breakpoints**: List all with `<Leader>mdp` (executes `dbstatus`)
- **Evaluation**: Execute expressions with `<Leader>mdx`

## Workflow

### Quick Start
1. Open MATLAB file in Neovim (inside tmux)
2. Start MATLAB server: `:MatlabStartServer`
3. Set breakpoints: `<Leader>mdb` on desired lines (enter condition when prompted, or leave empty for unconditional)
4. Edit breakpoint conditions: `<Leader>mde` on existing breakpoints
5. Start debugging: `<Leader>mds`
6. Step through code: `<Leader>mdo` / `<Leader>mdi` / `<Leader>mdt`
7. Inspect state: `<Leader>mdv` / `<Leader>mdk`
8. Stop debugging: `<Leader>mde`

### Debug Session Lifecycle
```
Start Server → Set Breakpoints → Start Debug → Step/Continue → Inspect → Stop Debug
     ↓              ↓                    ↓              ↓            ↓         ↓
:MatlabStartServer  <Leader>mdb       <Leader>mds    <Leader>mdc   <Leader>mdv :MatlabDebugStop
```

## Commands & Mappings

| Command | Default Mapping | Description |
|---------|-----------------|-------------|
| `:MatlabDebugStart` | `<Leader>mds` | Start debugging session |
| `:MatlabDebugStop` | `<Leader>mde` | Stop debugging session |
| `:MatlabDebugContinue` | `<Leader>mdc` | Continue to next breakpoint |
| `:MatlabDebugStepOver` | `<Leader>mdo` | Step over (execute line) |
| `:MatlabDebugStepInto` | `<Leader>mdi` | Step into function |
| `:MatlabDebugStepOut` | `<Leader>mdt` | Step out of function |
| `:MatlabDebugToggleBreakpoint` | `<Leader>mdb` | Toggle breakpoint at cursor |
| `:MatlabDebugClearBreakpoints` | `<Leader>mdd` | Clear all breakpoints |
| `:MatlabDebugEditBreakpoint` | `<Leader>mde` | Edit breakpoint condition |
| `:MatlabDebugShowVariables` | `<Leader>mdv` | Show variables (whos) |
| `:MatlabDebugShowStack` | `<Leader>mdk` | Show call stack (dbstack) |
| `:MatlabDebugShowBreakpoints` | `<Leader>mdp` | Show breakpoints (dbstatus) |
| `:MatlabDebugEval` | `<Leader>mdx` | Evaluate expression |

## MATLAB Commands Used

The plugin translates Neovim commands to these MATLAB debugging commands:

- `dbstop in file at line` - Set unconditional breakpoint
- `dbstop in file at line condition` - Set conditional breakpoint
- `dbclear file at line` - Clear specific breakpoint

**Note**: Conditional breakpoints use MATLAB expression syntax (e.g., `x > 5`, `length(data) > 10`, `strcmp(status, 'error')`). The condition is evaluated in MATLAB's workspace when the breakpoint line is reached.
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

- No automatic cursor positioning (shows location in MATLAB pane only)
- No conditional breakpoints
- No watch expressions
- No advanced debugging features (memory inspection, performance profiling)
- Requires tmux environment

## Troubleshooting

**Breakpoints not working**: Ensure line contains executable code (not comments/empty)
**Conditional breakpoints not triggering**: Verify condition syntax (e.g., `x > 5`, not `x>5`)
**Commands fail**: Verify MATLAB server is running (`:MatlabStartServer`)
**No output**: Check tmux MATLAB pane for debug information
**Lost breakpoints**: Use `:MatlabDebugShowBreakpoints` to verify MATLAB state
