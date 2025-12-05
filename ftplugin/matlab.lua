-- ftplugin/matlab.lua
-- Key mappings for MATLAB files

-- Only load this plugin once per buffer
if vim.b.did_ftplugin_matlab_nvim then
  return
end
vim.b.did_ftplugin_matlab_nvim = true

local config_ok, config = pcall(require, 'matlab.config')
if not config_ok then
  return
end

-- Check if mappings are enabled
if not config.get('default_mappings') then
  return
end

local mappings = config.get('mappings') or {}
local prefix = mappings.prefix or '<Leader>m'
local debug_prefix = prefix .. (mappings.debug_prefix or 'd')

-- Helper function to create buffer-local mapping
local function map(lhs, cmd, desc)
  vim.keymap.set('n', lhs, '<Cmd>' .. cmd .. '<CR>', { buffer = true, desc = desc, silent = true })
end

-- ============================================================================
-- General MATLAB Commands (<Leader>m + key)
-- ============================================================================

map(prefix .. (mappings.run or 'r'), 'MatlabRun', 'MATLAB: Run script')
map(prefix .. (mappings.run_cell or 'c'), 'MatlabRunCell', 'MATLAB: Run cell')
map(prefix .. (mappings.run_to_cell or 'C'), 'MatlabRunToCell', 'MATLAB: Run to cell')
map(prefix .. (mappings.doc or 'h'), 'MatlabDoc', 'MATLAB: Documentation')
map(prefix .. (mappings.workspace or 'w'), 'MatlabWorkspace', 'MATLAB: Show workspace')
map(prefix .. (mappings.workspace_pane or 'W'), 'MatlabToggleWorkspacePane', 'MATLAB: Toggle workspace pane')
map(prefix .. (mappings.clear_workspace or 'x'), 'MatlabClearWorkspace', 'MATLAB: Clear workspace')
map(prefix .. (mappings.toggle_cell_fold or 'f'), 'MatlabToggleCellFold', 'MATLAB: Toggle cell fold')
map(prefix .. (mappings.open_in_gui or 'g'), 'MatlabOpenInGUI', 'MATLAB: Open in GUI')

-- ============================================================================
-- Debug Commands (<Leader>md + key)
-- ============================================================================

map(debug_prefix .. (mappings.debug_start or 's'), 'MatlabDebugStart', 'MATLAB Debug: Start')
map(debug_prefix .. (mappings.debug_stop or 'q'), 'MatlabDebugStop', 'MATLAB Debug: Stop')
map(debug_prefix .. (mappings.debug_continue or 'c'), 'MatlabDebugContinue', 'MATLAB Debug: Continue')
map(debug_prefix .. (mappings.debug_step_over or 'n'), 'MatlabDebugStepOver', 'MATLAB Debug: Step over')
map(debug_prefix .. (mappings.debug_step_into or 'i'), 'MatlabDebugStepInto', 'MATLAB Debug: Step into')
map(debug_prefix .. (mappings.debug_step_out or 'o'), 'MatlabDebugStepOut', 'MATLAB Debug: Step out')
map(debug_prefix .. (mappings.debug_breakpoint or 'b'), 'MatlabDebugToggleBreakpoint', 'MATLAB Debug: Toggle breakpoint')
map(debug_prefix .. (mappings.debug_clear_bp or 'B'), 'MatlabDebugClearBreakpoints', 'MATLAB Debug: Clear breakpoints')
map(debug_prefix .. (mappings.debug_eval or 'e'), 'MatlabDebugEval', 'MATLAB Debug: Evaluate')
map(debug_prefix .. (mappings.debug_ui or 'u'), 'MatlabDebugUI', 'MATLAB Debug: Toggle sidebar')

-- ============================================================================
-- Help command to show all mappings
-- ============================================================================

vim.api.nvim_buf_create_user_command(0, 'MatlabKeymaps', function()
  local leader = vim.g.mapleader == ' ' and '<Space>' or (vim.g.mapleader or '\\')
  local p = leader .. 'm'
  local dp = p .. 'd'
  
  local lines = {
    'MATLAB Key Mappings',
    '═══════════════════════════════════════',
    '',
    'General (' .. p .. ' + key):',
    '  ' .. p .. 'r  - Run script',
    '  ' .. p .. 'c  - Run cell',
    '  ' .. p .. 'C  - Run to cell',
    '  ' .. p .. 'h  - Documentation',
    '  ' .. p .. 'w  - Show workspace (whos)',
    '  ' .. p .. 'W  - Toggle workspace pane',
    '  ' .. p .. 'x  - Clear workspace',
    '  ' .. p .. 'f  - Toggle cell fold',
    '  ' .. p .. 'g  - Open in GUI',
    '',
    'Debug (' .. dp .. ' + key):',
    '  ' .. dp .. 's  - Start debug',
    '  ' .. dp .. 'q  - Stop debug',
    '  ' .. dp .. 'c  - Continue',
    '  ' .. dp .. 'n  - Step over (next)',
    '  ' .. dp .. 'i  - Step into',
    '  ' .. dp .. 'o  - Step out',
    '  ' .. dp .. 'b  - Toggle breakpoint',
    '  ' .. dp .. 'B  - Clear all breakpoints',
    '  ' .. dp .. 'e  - Evaluate expression',
    '  ' .. dp .. 'u  - Toggle debug sidebar',
    '',
    'Global F-keys (during debug):',
    '  F5      - Continue / Start',
    '  F10     - Step over',
    '  F11     - Step into',
    '  F12     - Step out',
    '  Shift+F5 - Stop debug',
  }
  
  vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
end, {})
