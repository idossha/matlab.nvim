This is the architecture contract; [README.md](../README.md) covers setup. Deviations require
updating this file and appending to [DECISIONS.md](DECISIONS.md) in the same change.
Section numbers are stable and must not be renumbered.

# Architecture contract

## 1. MATLAB startup

Lua builds the MATLAB command and tmux hosts its interactive terminal, preserving
the existing architecture instead of adding a separate debugger transport.

**Editor suppression is session-local.** `suppress_editor_on_breakpoint` defaults
to true and applies `OpenFileAtBreakpoint.TemporaryValue = false` before startup
code. False leaves MATLAB's preference untouched. Failure warns and continues,
so older MATLAB releases remain usable. No persistent preference API is used.

**Figure support remains available.** Keep `-nodesktop -nosplash`; do not add
`-nodisplay`, `-nojvm`, or `-noFigureWindows` to suppress the editor.

## 2. Verification and scope

The dependency-free headless suite checks Lua behavior with controlled external
operations. [TESTING.md](TESTING.md) owns commands, fixtures, and acceptance checks.
CI runs the same suite; it cannot certify a licensed MATLAB desktop session.
Automatic navigation redesign and reconfiguring existing MATLAB panes are outside
this revision. No debugger framework or test-library dependency is introduced.

## 3. Component boundaries

| Component | Responsibility |
| --- | --- |
| `plugin/matlab.vim`, `ftplugin/matlab.lua` | MATLAB filetype detection and buffer-local mappings. Setup remains an explicit user call. |
| `lua/matlab/init.lua`, `config.lua` | Public commands, lifecycle autocommands, and merged configuration. |
| `lua/matlab/tmux.lua` | Executable discovery, terminal-pane lifecycle, startup arguments, and command transport. |
| `lua/matlab/commands.lua`, `cells.lua`, `workspace.lua` | Script/cell execution, cell folds, documentation, and workspace commands. |
| `lua/matlab/debug.lua` | Session state, breakpoint signs, native MATLAB debug commands, and location parsing. |
| `lua/matlab/debug_ui.lua` | Scratch-buffer sidebar, terminal-derived call stack, and temporary-file workspace exchange. |
| `lua/matlab/utils.lua` | Notifications and log output. |

**MATLAB remains the execution engine.** Lua sends native MATLAB statements through
tmux; no MATLAB Engine or Debug Adapter Protocol connection is maintained. Debugger
location updates inspect terminal output and match open buffer basenames. This makes
terminal formatting and duplicate filenames integration limits, not protocol guarantees.

**Configuration has one source of truth.** Defaults live in
[`config.lua`](../lua/matlab/config.lua). Setup deep-merges user options so nested
mapping overrides retain unrelated defaults. Examples in the README are configuration
examples, not a second defaults declaration.

## 4. Documentation and change boundaries

[DEBUGGING.md](DEBUGGING.md) owns the interactive debugger manual,
[TESTING.md](TESTING.md) owns verification, [RELEASING.md](RELEASING.md) owns publication,
and [ROADMAP.md](ROADMAP.md) records outstanding work. Historical reasons belong in
[DECISIONS.md](DECISIONS.md), not duplicate user guides.

Public startup behavior is defined by `lua/matlab/config.lua` and
`lua/matlab/tmux.lua`; changes to the editor setting, opt-out, or launch flags must
update this contract and its regression coverage together. An absent
`suppress_editor_on_breakpoint` option uses the enabled default described in §1.
Keep shell argument escaping separate from MATLAB string escaping to avoid commands
changing meaning when paths contain spaces or quotes.
