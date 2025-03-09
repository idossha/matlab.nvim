-- MATLAB filetype plugin
if vim.g.matlab_plugin_loaded then
  return
end

-- Set buffer options
vim.bo.commentstring = '%% %s'
vim.bo.tabstop = 4
vim.bo.shiftwidth = 4
vim.bo.softtabstop = 4
vim.bo.expandtab = true

-- Set up syntax highlighting if the plugin is loaded
if vim.g.loaded_matlab_nvim then
  -- Add highlight groups for MATLAB cells
  vim.api.nvim_set_hl(0, 'MatlabCellSeparator', { link = 'SpecialComment' })
  vim.api.nvim_set_hl(0, 'MatlabCellTitle', { bold = true, link = 'Title' })
end

-- Define pattern for MATLAB cells
vim.opt_local.sections:append('%%')
vim.opt_local.paragraphs:append('%%')

-- Enable spell checking in comments
vim.opt_local.spell = true
vim.opt_local.spelloptions:append('camel')

-- Set fold method to marker with %% as the marker
vim.opt_local.foldmethod = 'marker'
vim.opt_local.foldmarker = '%%,%%end'

-- Define text objects for MATLAB cells
vim.keymap.set('o', 'ac', function()
  -- Select around cell
  local cells = require('matlab.cells')
  local cell = cells.get_current_cell()
  
  if cell then
    vim.cmd('normal! ' .. (cell.start_line + 1) .. 'G0V' .. (cell.end_line + 1) .. 'G$')
  end
end, { buffer = true, desc = "Around MATLAB cell" })

vim.keymap.set('o', 'ic', function()
  -- Select inside cell (without the cell marker line)
  local cells = require('matlab.cells')
  local cell = cells.get_current_cell()
  
  if cell then
    vim.cmd('normal! ' .. (cell.start_line + 2) .. 'G0V' .. (cell.end_line + 1) .. 'G$')
  end
end, { buffer = true, desc = "Inside MATLAB cell" })

-- Set flag to avoid multiple loads
vim.g.matlab_plugin_loaded = true
