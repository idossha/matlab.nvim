This guide covers interactive debugging; see [README](../README.md) for setup and
[TESTING](TESTING.md) for verification and known coverage gaps.

# Debugging

### Keep debugging in Neovim, with MATLAB plots

New MATLAB sessions disable automatic editor opening at breakpoints using the
[documented MATLAB editor setting](https://www.mathworks.com/help/matlab/ref/matlab.editor-settings.html).
This applies only to that session; saved MATLAB preferences are unchanged.
Set `suppress_editor_on_breakpoint = false` to leave MATLAB's setting alone,
then restart the MATLAB server for the configuration change to take effect.

The plugin uses `-nodesktop -nosplash`, which permits separate figure windows.
`-nodisplay` disables display output and should not be used if you want plots.
On Linux, a working graphical display is still required.

For an already running MATLAB pane, execute:

```matlab
s = settings;
s.matlab.editor.OpenFileAtBreakpoint.TemporaryValue = false;
```

If your MATLAB version does not expose this setting, startup prints a warning
and continues. In MATLAB's **Preferences > Editor/Debugger**, disable automatic
file opening at breakpoints (wording varies by release). This manual preference
persists across sessions. Explicitly opening a file in MATLAB remains available;
this setting does not add debugger synchronization beyond the plugin's existing
Neovim debug commands.

### Quick Start

1. Open a saved MATLAB file inside tmux and run `:MatlabStartServer`.
2. Set breakpoints: `<Leader>mdb`
3. Start debugging: `<Leader>mds` or `:MatlabDebugStart`
4. Step through code:
   - `<Leader>mdc` or `F5` - Continue to next breakpoint
   - `<Leader>mdn` or `F10` - Step over
   - `<Leader>mdi` or `F11` - Step into
   - `<Leader>mdo` or `F12` - Step out
5. Stop debugging: `<Leader>mdq` (or `Shift+F5`)

### Debug Commands

| Key | Command | Description |
|-----|---------|-------------|
| `<Leader>mds` | `:MatlabDebugStart` | Start debugging |
| `<Leader>mdq` | `:MatlabDebugStop` | Stop debugging |
| `<Leader>mdc` | `:MatlabDebugContinue` | Continue execution |
| `<Leader>mdn` | `:MatlabDebugStepOver` | Step over line |
| `<Leader>mdi` | `:MatlabDebugStepInto` | Step into function |
| `<Leader>mdo` | `:MatlabDebugStepOut` | Step out of function |
| `<Leader>mdb` | `:MatlabDebugToggleBreakpoint` | Toggle breakpoint |
| `<Leader>mdB` | `:MatlabDebugClearBreakpoints` | Clear all breakpoints |
| `<Leader>mde` | `:MatlabDebugEval` | Evaluate expression |
| `<Leader>mdu` | `:MatlabDebugUI` | Toggle debug sidebar |

### Visual Indicators

- **Breakpoints**: Red circle (●) with full-line highlighting
- **Current line**: Blue arrow (▶) with full-line highlighting

### Debug Sidebar

Toggle with `<Leader>mdu` or `:MatlabDebugUI`. Shows call stack, breakpoints, and workspace variables.

| Key | Action |
|-----|--------|
| `q` | Close sidebar |
| `r` | Refresh display |
| `w` | Update workspace from MATLAB |
| `<CR>` | Jump to location under cursor |

### Debug Tips

- Files auto-save when starting debug session
- Breakpoints persist within Neovim session
- Use MATLAB commands directly in tmux pane (`whos`, `dbstack`, etc.)

### Conditional breakpoints and limits

Use MATLAB's native commands in the tmux pane for conditional breakpoints:

```matlab
dbstop in myfile at 22 if x > 5
dbstop in myfile at 33 if strcmp(status, 'error')
```

Breakpoints added directly in MATLAB are not imported into Neovim's breakpoint list.
The sidebar has no watch-expression editor. Location updates parse recent MATLAB
terminal output and match open buffers by filename; they are not a debugger protocol.
Use `:MatlabDebugUpdateLine` to retry a stale location update, or inspect `dbstack`
and `dbstatus` directly in MATLAB. Files with the same basename can be ambiguous.

F-key mappings are installed globally during a debug session and removed when it
ends. The plugin does not restore pre-existing global F-key mappings.
