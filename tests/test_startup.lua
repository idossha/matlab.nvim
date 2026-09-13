-- Test the emitted shell command as a public transport contract, using a real
-- shell and fake executable. MATLAB semantics are checked separately.
return function(test)
  local config = require('matlab.config')
  local tmux = require('matlab.tmux')
  local root = vim.fn.tempname() .. " startup's files"
  vim.fn.mkdir(root, 'p')
  local executable = root .. '/fake matlab'
  vim.fn.writefile({ '#!/bin/sh', [[printf '%s\n' "$MATLAB_TEST_VALUE" "$@"]] }, executable)
  vim.fn.setfperm(executable, 'rwx------')
  local function startup_args(opts, env)
    config.setup(opts)
    local command = tmux.build_matlab_command(executable, "disp('user startup');", env or {})
    local args = vim.fn.systemlist(command)
    assert(vim.v.shell_error == 0, table.concat(args, '\n'))
    return args
  end
  test('startup quotes executable paths and preserves figure-compatible arguments', function()
    local args = startup_args({})
    assert(#args == 5, vim.inspect(args))
    assert(args[2] == '-nodesktop' and args[3] == '-nosplash')
    assert(args[4] == '-r' or args[4] == '/r')
    local setting = assert(args[5]:find('OpenFileAtBreakpoint.TemporaryValue = false', 1, true))
    assert(setting < assert(args[5]:find("disp('user startup');", 1, true)))
    assert(not args[5]:find('PersonalValue', 1, true))
  end)
  test('startup opt-out leaves user code untouched', function()
    assert(startup_args({ suppress_editor_on_breakpoint = false })[5] == "disp('user startup');")
  end)
  test('startup transports shell metacharacters literally in environment values', function()
    local value = [[a'b "quoted" $HOME $(echo unsafe); `echo unsafe`]]
    assert(startup_args({}, { MATLAB_TEST_VALUE = value })[1] == value)
  end)
  test('invalid environment names are ignored', function()
    assert(startup_args({}, { ['BAD; echo unsafe'] = 'value' })[1] == '')
  end)
  vim.fn.delete(root, 'rf')
  config.setup({})
end
