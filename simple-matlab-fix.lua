-- Save this as simple-matlab-fix.lua and run it with:
-- nvim --clean -u simple-matlab-fix.lua

-- Basic setup - doesn't rely on any existing configuration
vim.g.mapleader = " "  -- Set space as leader
vim.cmd('set ft=matlab')  -- Force filetype to matlab

-- Create some basic MATLAB commands for testing
vim.api.nvim_create_user_command('MatlabRun', function()
  print("MATLAB Run command executed")
end, {})

vim.api.nvim_create_user_command('MatlabBreakpoint', function()
  print("MATLAB Breakpoint command executed")
end, {})

-- Try setting mappings with different approaches
-- Approach 1: Direct space prefix
vim.keymap.set('n', ' mr', '<cmd>MatlabRun<CR>', {desc = "MATLAB Run (space)"})

-- Approach 2: With leader notation
vim.keymap.set('n', '<Leader>mb', '<cmd>MatlabBreakpoint<CR>', {desc = "MATLAB Breakpoint (leader)"})

-- Approach 3: Alternative non-space mapping
vim.keymap.set('n', ',mr', '<cmd>MatlabRun<CR>', {desc = "MATLAB Run (comma)"})

-- Print all the mappings to check what's actually set
print("All mappings:")
local all_maps = vim.api.nvim_get_keymap('n')
for _, map in ipairs(all_maps) do
  if map.desc and map.desc:find("MATLAB") then
    print(string.format("'%s' -> %s (%s)", map.lhs, map.rhs, map.desc))
  end
end

-- Create a test mapping command to check mappings in normal usage
vim.api.nvim_create_user_command('TestMatlabMappings', function()
  local mappings = vim.api.nvim_get_keymap('n')
  local lines = {"MATLAB mappings:"}
  
  for _, map in ipairs(mappings) do
    if map.desc and map.desc:find("MATLAB") then
      table.insert(lines, "- '" .. map.lhs .. "' -> " .. map.rhs)
    end
  end
  
  if #lines == 1 then
    table.insert(lines, "No MATLAB mappings found!")
  end
  
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end, {})

print("Setup complete - type :TestMatlabMappings to see available MATLAB mappings")
