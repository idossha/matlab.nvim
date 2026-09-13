-- Dependency-free behavioral suite. Run from the repository root with Neovim 0.9+.
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.o.swapfile = false
vim.o.shadafile = 'NONE'
vim.ui.select = function() error('Unexpected interactive selection in headless tests') end
vim.ui.input = function() error('Unexpected interactive input in headless tests') end
local passed, failed = 0, 0
local function test(name, fn)
  local ok, err = xpcall(fn, debug.traceback)
  if ok then
    passed = passed + 1
    print('PASS ' .. name)
  else
    failed = failed + 1
    print('FAIL ' .. name .. '\n' .. err)
  end
end
local suites = vim.fn.glob('tests/test_*.lua', false, true)
assert(#suites > 0, 'No test suites found')
table.sort(suites)
for _, path in ipairs(suites) do
  local ok, register = pcall(dofile, path)
  if ok and type(register) == 'function' then
    register(test)
  else
    failed = failed + 1
    print('FAIL loading ' .. path .. ': ' .. tostring(register))
  end
end
print(string.format('%d passed, %d failed', passed, failed))
if failed > 0 or passed == 0 then
  vim.cmd('cquit 1')
end
vim.cmd('qa!')
