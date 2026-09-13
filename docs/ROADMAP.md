This page tracks outstanding verification and scope; [ARCHITECTURE.md](ARCHITECTURE.md)
defines current behavior and [TESTING.md](TESTING.md) describes acceptance checks.

# Roadmap

## What exists

- tmux-hosted MATLAB execution, cells, workspace commands, and native debugger controls.
- Session-local editor suppression with an opt-out and figure-compatible startup flags.
- Headless Lua regression checks and consolidated contributor/debugging manuals.

## What is next

- Complete the MATLAB integration checklist across supported user environments,
  recording releases and results before claiming editor/figure compatibility.
- Grow regression coverage around reproduced defects, especially terminal-output
  variations and debugger lifecycle behavior.

A debugger transport redesign, watch-expression UI, benchmarks, and a documentation
website are not accepted scope. Add a separate manual only when such a surface exists.
