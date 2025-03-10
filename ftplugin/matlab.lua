-- ftplugin for MATLAB files

-- Only load this plugin once per buffer
if vim.b.did_ftplugin_matlab_nvim then
  return
end
vim.b.did_ftplugin_matlab_nvim = true

local config = require('matlab.config')

-- Apply keymappings for this buffer
local matlab = require('matlab')
matlab.apply_keymappings()