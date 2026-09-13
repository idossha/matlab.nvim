-- Explicit licensed integration check; separate from the default suite and CI.
-- MATLAB executes the exact startup statement emitted through a real shell.
vim.opt.rtp:prepend(vim.fn.getcwd())
local executable = vim.env.MATLAB_NVIM_EXECUTABLE
if not executable or executable == '' then
  print('SKIP: set MATLAB_NVIM_EXECUTABLE to a licensed MATLAB executable')
  vim.cmd('qa!')
  return
end
local root = vim.fn.tempname()
vim.fn.mkdir(root, 'p')
local capture = root .. '/capture'
vim.fn.writefile({ '#!/bin/sh', [[printf '%s\n' "$@"]] }, capture)
vim.fn.setfperm(capture, 'rwx------')
require('matlab.config').setup({})
local command = require('matlab.tmux').build_matlab_command(capture, '', {})
local args = vim.fn.systemlist(command)
assert(vim.v.shell_error == 0 and #args == 4, 'could not decode startup arguments')
local script = root .. '/check_startup.m'
vim.fn.writefile({
  's = settings;',
  'p = s.matlab.editor.OpenFileAtBreakpoint;',
  'hadPersonal = hasPersonalValue(p);',
  'if hadPersonal; savedPersonal = p.PersonalValue; end;',
  args[4],
  'assert(p.ActiveValue == false);',
  'assert(hasPersonalValue(p) == hadPersonal);',
  'if hadPersonal; assert(isequal(p.PersonalValue, savedPersonal)); end;',
  "assert(exist('matlab_nvim_settings', 'var') == 0);",
  "f = figure('Visible', 'off'); plot(1:3);",
  "assert(numel(findobj(f, 'Type', 'line')) == 1); close(f);",
  "disp('PASS: temporary setting, saved preference, workspace cleanup, hidden plot');",
}, script)
local output = vim.fn.system({ executable, '-batch', "run('" .. script:gsub("'", "''") .. "')" })
local status = vim.v.shell_error
print(output)
vim.fn.delete(root, 'rf')
if status ~= 0 then
  print('FAIL: MATLAB integration exited with ' .. status)
  vim.cmd('cquit 1')
end
vim.cmd('qa!')
