-- Minimal init file for running tests
-- Sets up necessary environment without full Neovim config

-- Add project root to runtime path
local project_root = vim.fn.fnamemodify(vim.fn.getcwd(), ':p')
vim.opt.runtimepath:append(project_root)

-- Add plenary to runtime path (adjust path as needed)
local plenary_path = vim.fn.stdpath('data') .. '/lazy/plenary.nvim'
if vim.fn.isdirectory(plenary_path) == 1 then
  vim.opt.runtimepath:append(plenary_path)
end

-- Minimal vim settings for tests
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.writebackup = false

-- Required for some tests
vim.g.mapleader = ' '

-- Print test environment info
print('Test environment initialized')
print('Project root: ' .. project_root)
print('Neovim version: ' .. vim.version().major .. '.' .. vim.version().minor .. '.' .. vim.version().patch)
