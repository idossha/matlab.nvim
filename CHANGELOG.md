# Changelog

## [Unreleased]

### Fixed

- **Keep the MATLAB editor from opening at breakpoints** — newly launched sessions
  apply a temporary editor setting while retaining figure support. Set
  `suppress_editor_on_breakpoint = false` to keep MATLAB's own behavior. Saved
  preferences are unchanged; releases without the setting warn and require the
  manual Editor/Debugger preference.
- **Execute the selected cell accurately** — a section marker belongs to its own
  cell, the first unmarked line is included, and execution stops before the next cell.
- **Keep terminal commands intact** — MATLAB executable paths support spaces and
  quotes, existing tmux panes are recognized by exact ID, and code is sent literally
  without adding escapes to MATLAB strings.

### Added

- **Contributor and testing guidance** — focused manuals and a dependency-free
  headless regression suite run by CI. Live MATLAB checks remain separately opt-in.
