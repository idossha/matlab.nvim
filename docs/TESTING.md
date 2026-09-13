This manual verifies the [architecture contract](ARCHITECTURE.md); see
[DEBUGGING.md](DEBUGGING.md) for user-facing commands and [CONTRIBUTIONS.md](../CONTRIBUTIONS.md)
for the development workflow.

# Testing

## Automated regression suite

From the repository root:

```sh
nvim --headless -u NONE -l tests/run.lua
```

Use Neovim 0.9 or newer for this `-l` test runner. It runs without user configuration,
a MATLAB installation, or a running tmux session. External operations are replaced
with controlled test doubles; failures must produce a nonzero exit status.
Coverage includes configuration overrides, cell selection boundaries, startup
argument quoting and editor-setting order, environment overrides, tmux pane IDs and
command transport, debugger breakpoint signs and stepping controls, and setup/mapping
registration. CI runs this same command on Ubuntu; it exercises plugin behavior
rather than launching an interactive session.

## Optional MATLAB batch check

With a licensed MATLAB installation, run separately from the Lua suite:

```sh
MATLAB_NVIM_EXECUTABLE=/path/to/matlab nvim --headless -u NONE -l tests/check_matlab.lua
```

This explicitly opted-in check launches MATLAB in batch mode. It is not run by CI.
See the script for its assertions; batch execution does not prove interactive editor
or displayed-figure behavior. Startup or licensing failure remains a failed check,
not evidence against or for the plugin's interactive behavior.

## MATLAB integration acceptance

The automated Lua suite does not prove MATLAB licensing, startup compatibility,
terminal timing, editor suppression at a real breakpoint, or displayed figures.
Record MATLAB release, OS, Neovim version, and observed results when checking these.
A skipped or unavailable MATLAB check is not a passing integration test.

For a human-run interactive check inside tmux, open [test_debug.m](../tests/test_debug.m)
and follow [DEBUGGING.md](DEBUGGING.md). Select executable statements by their content,
not fixed line numbers that move when the fixture changes:

| Scenario | Check |
| --- | --- |
| Basic stepping | Break at `z = x + y`, inspect `x` and `y`, step, and confirm `z` is 30. |
| Loops | Break inside the summation loop; confirm the final sum is 15. |
| Branches | Confirm `value = 42` selects the `medium` branch. |
| Functions | Step into `compute_factorial`, inspect `dbstack`, step out, and confirm the result is 5040. |
| Recursion and call chains | Step through nested functions and confirm the stack grows and unwinds. |
| Expressions | Evaluate `x + y`, `sum(A(:))`, and `struct_data.name` while paused. |
| Errors | Enable the fixture's commented error and confirm execution enters its catch block. |
| Breakpoint state | Compare Neovim-created breakpoints with MATLAB `dbstatus`; clear and restart debugging. |
| Cleanup | Stop debugging and confirm the current-line indicator and temporary debug mappings are removed. |

For the editor-suppression change, start a fresh session, stop at a breakpoint, and
confirm no editor opens. Check that `OpenFileAtBreakpoint.ActiveValue` is false while
its saved preference is unchanged. Run `figure; plot(1:3)` and confirm a separate
figure is available. Repeat with the configuration opt-out and confirm MATLAB's own
setting is left alone. Older releases without the setting must warn and keep starting.

Automated GUI checks must run hidden and must not take the user's screen. The
interactive checklist above is for a human testing an ordinary editor session.
The scripts in this directory are fixtures, not an automated MATLAB assertion suite;
`img.m` is a plotting example, not a release gate.

## Adding regression coverage

Use small, deterministic buffers and independent expected commands or values.
Exercise failure paths as well as the reported defect. Keep external MATLAB checks
optional and explicitly labeled; do not replace a live integration claim with a mock.
Avoid sleeps, personal paths, and dependencies added solely for assertion helpers.
