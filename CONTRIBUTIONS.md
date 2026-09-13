This guide covers contributions; [docs/TESTING.md](docs/TESTING.md) owns test commands
and [docs/RELEASING.md](docs/RELEASING.md) owns publication checks.

# Contributing

Clone the repository and add the checkout to Neovim's runtime path, then call
`require('matlab').setup()` in a disposable development configuration. Normal use
requires MATLAB and tmux; the automated Lua suite does not.

Keep changes focused and follow the existing Lua modules and two-space indentation.
Preserve user configuration and avoid unrelated formatting changes. Add a regression
case for a behavior fix, update its authoritative documentation, and describe
user-visible changes in [CHANGELOG.md](CHANGELOG.md).

Before opening a pull request, run the checks in the testing manual and `git diff --check`.
Describe the defect, resulting behavior, commands run, and any unverified MATLAB or
platform behavior. Include reproduction steps and versions for bug reports. Never
include license files, credentials, private workspace data, or personal startup scripts.
