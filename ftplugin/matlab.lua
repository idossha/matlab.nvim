-- ftplugin for MATLAB files

-- Only load this plugin once per buffer
if vim.b.did_ftplugin_matlab_nvim then
  return
end
vim.b.did_ftplugin_matlab_nvim = true

local config = require('matlab.config')

-- Ensure mappings are defined even if there's a configuration issue
local function get_safe_mappings()
  -- Check if mappings exist in config
  local user_mappings = config.get('mappings')
  
  -- Default mappings as fallback
  local default_mappings = {
    prefix = '<Leader>m',
    run = 'r',
    run_cell = 'c',
    run_to_cell = 't',
    breakpoint = 'b',
    clear_breakpoint = 'd',
    clear_breakpoints = 'D',
    doc = 'h',
    toggle_workspace = 'w',
    show_workspace = 'W',
    clear_workspace = 'x',
    save_workspace = 's',
    load_workspace = 'l',
    toggle_cell_fold = 'f',
    toggle_all_cell_folds = 'F',
  }
  
  -- If user_mappings doesn't exist or is malformed, use defaults
  if type(user_mappings) ~= 'table' then
    vim.notify("MATLAB: Using default mappings (config.mappings is not a table)", vim.log.levels.WARN)
    return default_mappings
  end
  
  -- Merge user_mappings with defaults
  for k, v in pairs(default_mappings) do
    if user_mappings[k] == nil then
      user_mappings[k] = v
    end
  end
  
  return user_mappings
end

-- Print debug info
local function debug_info(message)
  if config.get('debug') then
    vim.notify("MATLAB Debug: " .. message, vim.log.levels.INFO)
  end
end

-- Set up key mappings if enabled in config
if config.get('default_mappings') then
  local mappings = get_safe_mappings()
  local prefix = mappings.prefix
  
  -- Log mapping information
  debug_info("Setting up MATLAB mappings with prefix: " .. prefix)
  
  -- Directly set some important mappings with space for testing
  if vim.g.mapleader == " " then
    -- Test explicit space mappings
    local space_mappings = {
      [' mr'] = '<Cmd>MatlabRun<CR>',
      [' mc'] = '<Cmd>MatlabRunCell<CR>',
      [' mb'] = '<Cmd>MatlabBreakpoint<CR>',
      [' mh'] = '<Cmd>MatlabDoc<CR>',
      [' mw'] = '<Cmd>MatlabToggleWorkspace<CR>'
    }
    
    for lhs, rhs in pairs(space_mappings) do
      vim.keymap.set('n', lhs, rhs, { buffer = true, desc = 'MATLAB command' })
      debug_info("Set explicit space mapping: " .. lhs)
    end
  end
  
  -- Run commands - with more debugging
  local map_run = prefix .. mappings.run
  debug_info("Setting mapping: " .. map_run)
  vim.keymap.set('n', map_run, '<Cmd>MatlabRun<CR>', { buffer = true, desc = 'Run MATLAB script' })
  
  vim.keymap.set('n', prefix .. mappings.run_cell, '<Cmd>MatlabRunCell<CR>', { buffer = true, desc = 'Run current MATLAB cell' })
  vim.keymap.set('n', prefix .. mappings.run_to_cell, '<Cmd>MatlabRunToCell<CR>', { buffer = true, desc = 'Run to current MATLAB cell' })

  -- Breakpoints
  vim.keymap.set('n', prefix .. mappings.breakpoint, '<Cmd>MatlabBreakpoint<CR>', { buffer = true, desc = 'Set MATLAB breakpoint' })
  vim.keymap.set('n', prefix .. mappings.clear_breakpoint, '<Cmd>MatlabClearBreakpoint<CR>', { buffer = true, desc = 'Clear MATLAB breakpoint' })
  vim.keymap.set('n', prefix .. mappings.clear_breakpoints, '<Cmd>MatlabClearBreakpoints<CR>', { buffer = true, desc = 'Clear all MATLAB breakpoints' })

  -- Documentation
  vim.keymap.set('n', prefix .. mappings.doc, '<Cmd>MatlabDoc<CR>', { buffer = true, desc = 'Show MATLAB documentation' })

  -- Workspace
  vim.keymap.set('n', prefix .. mappings.toggle_workspace, '<Cmd>MatlabToggleWorkspace<CR>', { buffer = true, desc = 'Toggle MATLAB workspace window' })
  vim.keymap.set('n', prefix .. mappings.show_workspace, '<Cmd>MatlabWorkspace<CR>', { buffer = true, desc = 'Show MATLAB workspace in tmux' })
  vim.keymap.set('n', prefix .. mappings.clear_workspace, '<Cmd>MatlabClearWorkspace<CR>', { buffer = true, desc = 'Clear MATLAB workspace' })
  vim.keymap.set('n', prefix .. mappings.save_workspace, '<Cmd>MatlabSaveWorkspace<CR>', { buffer = true, desc = 'Save MATLAB workspace' })
  vim.keymap.set('n', prefix .. mappings.load_workspace, '<Cmd>MatlabLoadWorkspace<CR>', { buffer = true, desc = 'Load MATLAB workspace' })
  
  -- Cell folding
  vim.keymap.set('n', prefix .. mappings.toggle_cell_fold, '<Cmd>MatlabToggleCellFold<CR>', { buffer = true, desc = 'Toggle current MATLAB cell fold' })
  vim.keymap.set('n', prefix .. mappings.toggle_all_cell_folds, '<Cmd>MatlabToggleAllCellFolds<CR>', { buffer = true, desc = 'Toggle all MATLAB cell folds' })
  
  -- Additional mapping for commonly used functions using just the prefix
  vim.keymap.set('n', prefix, '<Cmd>MatlabRun<CR>', { buffer = true, desc = 'Run MATLAB script (shortcut)' })
  
  -- Add command to view key mappings
  vim.api.nvim_buf_create_user_command(0, 'MatlabKeymaps', function()
    local lines = {"MATLAB key mappings:"}
    table.insert(lines, "- " .. prefix .. mappings.run .. " : Run MATLAB script")
    table.insert(lines, "- " .. prefix .. mappings.run_cell .. " : Run current MATLAB cell")
    table.insert(lines, "- " .. prefix .. mappings.run_to_cell .. " : Run to current MATLAB cell")
    table.insert(lines, "- " .. prefix .. mappings.breakpoint .. " : Set breakpoint")
    table.insert(lines, "- " .. prefix .. mappings.clear_breakpoint .. " : Clear breakpoint")
    table.insert(lines, "- " .. prefix .. mappings.doc .. " : Show documentation")
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, {})
end