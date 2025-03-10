-- Save as test-matlab-mappings.lua
vim.g.mapleader = " "  -- Set space as leader
vim.cmd('set ft=matlab') -- Set filetype to matlab
vim.cmd('runtime ftplugin/matlab.lua') -- Load the ftplugin

-- List all normal mode mappings
print("All mappings:")
local all_maps = vim.api.nvim_get_keymap('n')
for _, map in ipairs(all_maps) do
  if map.desc and map.desc:find("MATLAB") then
    print(string.format("'%s' -> %s (%s)", map.lhs, map.rhs or "<function>", map.desc))
  end
end
