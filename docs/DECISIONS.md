See [the architecture contract](ARCHITECTURE.md) for current behavior and
[ROADMAP.md](ROADMAP.md) for outstanding work.

# Decisions

## 2026-09-12 — Suppress automatic editor opening per session

The supplied discussion requests Neovim debugging with MATLAB figure windows.
Use the documented `OpenFileAtBreakpoint.TemporaryValue` setting before startup
code. Default suppression to enabled, with a configuration opt-out. Warn and
continue if unavailable. Persistent preferences would affect unrelated desktop
sessions; `-nodisplay` would remove the requested plots; undocumented Java
preferences would introduce a version-dependent compatibility dependency.

Startup command checks live in `tests/test_startup.lua`. Interactive breakpoint
and visible figure behavior require MATLAB integration verification separately.

## 2026-09-12 — Consolidate manuals and add headless regression coverage

Keep detailed debugging and testing guidance under `docs/`, with a short testing
README redirect and removal of the obsolete root debugging manual, so command
tables have one maintained home.
Use Neovim itself to run deterministic Lua regression cases with controlled tmux
and MATLAB boundaries. This keeps local and CI checks reproducible without a test
framework or MATLAB license. Live editor and figure behavior stays a separate
integration acceptance check; a passing mock-based suite cannot prove it.

CI uses one Ubuntu job with the distribution's Neovim package and the same local
test runner. There is no licensed MATLAB job or extra test framework; this keeps
routine validation inexpensive. Regression cases exposed and now cover cell-range
indexing, executable shell quoting, literal tmux command delivery, and pane identity.
