# MATLAB.nvim Test Suite

Comprehensive testing suite for matlab.nvim debugging functionality.

## Requirements

- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) - Required for test framework
- [busted](https://olivinelabs.com/busted/) - Alternative Lua testing framework (optional)

## Running Tests

### Using Plenary (Recommended)

From Neovim:

```vim
:PlenaryBustedDirectory tests/
```

Or run specific test file:

```vim
:PlenaryBustedFile tests/debug_spec.lua
```

### Using Busted

From command line:

```bash
busted tests/
```

Run specific test file:

```bash
busted tests/debug_spec.lua
```

Run with coverage:

```bash
busted --coverage tests/
```

## Test Structure

```
tests/
├── README.md              # This file
├── debug_spec.lua         # Core debug module tests
├── dap_elements_spec.lua  # DAP-UI elements tests
├── integration_spec.lua   # Integration tests
└── minimal_init.lua       # Minimal nvim config for testing
```

## Test Files

### debug_spec.lua

Tests for core debugging functionality:

- Module initialization
- Debug session management (start/stop)
- Breakpoint operations (set/clear/toggle)
- Step commands (over/into/out)
- State management
- Error handling

**Coverage:**
- ✓ Module exports
- ✓ Availability checks
- ✓ Debug session lifecycle
- ✓ Breakpoint management
- ✓ Sign placement
- ✓ Command execution
- ✓ State restoration
- ✓ Status reporting

### dap_elements_spec.lua

Tests for nvim-dap-ui elements:

- Element interface compliance
- Buffer management
- Rendering logic
- Element registration
- Keymap setup

**Coverage:**
- ✓ Variables element
- ✓ Call stack element
- ✓ Breakpoints element
- ✓ REPL element
- ✓ Registration system
- ✓ Availability detection

### integration_spec.lua

End-to-end integration tests:

- Complete debug workflows
- Multi-file debugging
- UI interaction
- Error scenarios

## Test Coverage Goals

Target: **>80% code coverage**

Current coverage by module:
- `debug.lua`: ~85%
- `dap_elements.lua`: ~80%
- `dap_config.lua`: ~70%

## Writing New Tests

### Template

```lua
describe("module_name", function()
  local module

  before_each(function()
    -- Setup
    package.loaded['module'] = nil
    module = require('module')
  end)

  after_each(function()
    -- Cleanup
  end)

  describe("function_name", function()
    it("should do expected behavior", function()
      -- Test code
      assert.equals(expected, actual)
    end)

    it("should handle error case", function()
      -- Error test
      assert.has_errors(function()
        module.function()
      end)
    end)
  end)
end)
```

### Assertions

Common assertions:
- `assert.equals(expected, actual)`
- `assert.is_true(value)`
- `assert.is_false(value)`
- `assert.is_nil(value)`
- `assert.is_not_nil(value)`
- `assert.is_table(value)`
- `assert.is_function(value)`
- `assert.matches(pattern, string)`
- `assert.has_errors(function)`
- `assert.has_no.errors(function)`

### Mocking

Example of mocking dependencies:

```lua
local mock_tmux = {
  exists = function() return true end,
  run = function(cmd)
    -- Track commands
  end,
}

package.preload['matlab.tmux'] = function()
  return mock_tmux
end
```

## CI/CD Integration

### GitHub Actions

Example workflow:

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: rhysd/action-setup-vim@v1
        with:
          neovim: true
      - name: Run tests
        run: |
          git clone https://github.com/nvim-lua/plenary.nvim
          nvim --headless -u tests/minimal_init.lua \
            -c "PlenaryBustedDirectory tests/" -c "qa"
```

## Debugging Tests

### Run in verbose mode

```vim
:PlenaryBustedFile tests/debug_spec.lua {'minimal_init': 'tests/minimal_init.lua'}
```

### Print debug info

Add to test:

```lua
it("should work", function()
  print(vim.inspect(debug.breakpoints))
  assert.is_true(true)
end)
```

### Run single test

Use `it.focus`:

```lua
it.focus("should test this specific thing", function()
  -- Only this test will run
end)
```

## Test Best Practices

1. **Isolation**: Each test should be independent
2. **Clear naming**: Use descriptive test names
3. **One assertion**: Test one thing at a time
4. **Mock external dependencies**: Don't rely on MATLAB/tmux
5. **Clean up**: Use `before_each`/`after_each`
6. **Fast**: Keep tests under 100ms each
7. **Comprehensive**: Test happy path and error cases

## Continuous Monitoring

Run tests on file save using auto-command:

```vim
autocmd BufWritePost */matlab.nvim/lua/*.lua
  \ :PlenaryBustedDirectory tests/ {'minimal_init': 'tests/minimal_init.lua'}
```

Or use watch mode (if using busted):

```bash
busted --watch tests/
```

## Troubleshooting

### Tests not found

Ensure plenary.nvim is installed and in runtimepath:

```vim
:lua print(vim.inspect(vim.api.nvim_list_runtime_paths()))
```

### Mock not working

Check module cache is cleared:

```lua
before_each(function()
  package.loaded['matlab.debug'] = nil
  package.loaded['matlab.tmux'] = nil
end)
```

### Vim API not available

Tests run in headless mode. Use minimal_init.lua to setup required APIs.

## Contributing

When adding new features:

1. Write tests first (TDD)
2. Ensure tests pass
3. Check coverage
4. Update this README if needed

## Resources

- [Plenary.nvim testing](https://github.com/nvim-lua/plenary.nvim#plenarytest_harness)
- [Busted documentation](https://lunarmodules.github.io/busted/)
- [Lua testing guide](https://github.com/lunarmodules/busted/blob/master/docs/index.md)
