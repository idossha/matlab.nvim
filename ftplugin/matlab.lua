-- Save this as ftplugin/matlab.lua (replacing your current version)
-- Space Leader Fix for MATLAB.nvim

-- Only load this plugin once per buffer
if vim.b.did_ftplugin_matlab_nvim then
  return
end
vim.b.did_ftplugin_matlab_nvim = true

local config = require('matlab.config')

-- Enhanced debug function
local function debug_info(message)
  if config.get('debug') then
    vim.notify("MATLAB Debug: " .. message, vim.log.levels.INFO)
  end
end

-- Log important startup info
debug_info("MATLAB ftplugin loading for " .. vim.api.nvim_buf_get_name(0))

-- Ensure mappings are defined even if there's a configuration issue
local function get_safe_mappings()
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
  
  if type(user_mappings) ~= 'table' then
    vim.notify("MATLAB: Using default mappings (config.mappings is not a table)", vim.log.levels.WARN)
    return default_mappings
  end
  
  for k, v in pairs(default_mappings) do
    if user_mappings[k] == nil then
      user_mappings[k] = v
    end
  end
  
  return user_mappings
end

-- Set up key mappings if enabled in config
if config.get('default_mappings') then
  local mappings = get_safe_mappings()
  local prefix = mappings.prefix
  
  -- Log mapping information
  debug_info("Setting up MATLAB mappings with prefix: " .. prefix)
  
  -- IMPORTANT FIX: Determine if leader is space and handle it specially
  local is_space_leader = vim.g.mapleader == " "
  debug_info("Space leader detected: " .. tostring(is_space_leader))
  
  -- Set explicit space mappings if leader is space
  if is_space_leader then
    -- Convert <Leader>m to  m (space+m)
    local explicit_prefix = string.gsub(prefix, "<Leader>", " ")
    debug_info("Using explicit space prefix: '" .. explicit_prefix .. "'")
    
    -- Define all mappings with explicit space
    vim.keymap.set('n', explicit_prefix .. mappings.run, '<Cmd>MatlabRun<CR>', 
                 { buffer = true, desc = 'Run MATLAB script' })
    
    vim.keymap.set('n', explicit_prefix .. mappings.run_cell, '<Cmd>MatlabRunCell<CR>', 
                 { buffer = true, desc = 'Run current MATLAB cell' })
    
    vim.keymap.set('n', explicit_prefix .. mappings.run_to_cell, '<Cmd>MatlabRunToCell<CR>', 
                 { buffer = true, desc = 'Run to current MATLAB cell' })

    -- Breakpoints
    vim.keymap.set('n', explicit_prefix .. mappings.breakpoint, '<Cmd>MatlabBreakpoint<CR>', 
                 { buffer = true, desc = 'Set MATLAB breakpoint' })
    
    vim.keymap.set('n', explicit_prefix .. mappings.clear_breakpoint, '<Cmd>MatlabClearBreakpoint<CR>', 
                 { buffer = true, desc = 'Clear MATLAB breakpoint' })
    
    vim.keymap.set('n', explicit_prefix .. mappings.clear_breakpoints, '<Cmd>MatlabClearBreakpoints<CR>', 
                 { buffer = true, desc = 'Clear all MATLAB breakpoints' })

    -- Documentation
    vim.keymap.set('n', explicit_prefix .. mappings.doc, '<Cmd>MatlabDoc<CR>', 
                 { buffer = true, desc = 'Show MATLAB documentation' })

    -- Workspace
    vim.keymap.set('n', explicit_prefix .. mappings.toggle_workspace, '<Cmd>MatlabToggleWorkspace<CR>', 
                 { buffer = true, desc = 'Toggle MATLAB workspace window' })
    
    vim.keymap.set('n', explicit_prefix .. mappings.show_workspace, '<Cmd>MatlabWorkspace<CR>', 
                 { buffer = true, desc = 'Show MATLAB workspace in tmux' })
    
    vim.keymap.set('n', explicit_prefix .. mappings.clear_workspace, '<Cmd>MatlabClearWorkspace<CR>', 
                 { buffer = true, desc = 'Clear MATLAB workspace' })
    
    vim.keymap.set('n', explicit_prefix .. mappings.save_workspace, '<Cmd>MatlabSaveWorkspace<CR>', 
                 { buffer = true, desc = 'Save MATLAB workspace' })
    
    vim.keymap.set('n', explicit_prefix .. mappings.load_workspace, '<Cmd>MatlabLoadWorkspace<CR>', 
                 { buffer = true, desc = 'Load MATLAB workspace' })
    
    -- Cell folding
    vim.keymap.set('n', explicit_prefix .. mappings.toggle_cell_fold, '<Cmd>MatlabToggleCellFold<CR>', 
                 { buffer = true, desc = 'Toggle current MATLAB cell fold' })
    
    vim.keymap.set('n', explicit_prefix .. mappings.toggle_all_cell_folds, '<Cmd>MatlabToggleAllCellFolds<CR>', 
                 { buffer = true, desc = 'Toggle all MATLAB cell folds' })
    
    -- Additional mapping for just the prefix 
    vim.keymap.set('n', explicit_prefix, '<Cmd>MatlabRun<CR>', 
                 { buffer = true, desc = 'Run MATLAB script (shortcut)' })
  else
    -- For non-space leader, use standard <Leader> syntax
    -- Run commands
    vim.keymap.set('n', prefix .. mappings.run, '<Cmd>MatlabRun<CR>', 
                 { buffer = true, desc = 'Run MATLAB script' })
    
    vim.keymap.set('n', prefix .. mappings.run_cell, '<Cmd>MatlabRunCell<CR>', 
                 { buffer = true, desc = 'Run current MATLAB cell' })
    
    vim.keymap.set('n', prefix .. mappings.run_to_cell, '<Cmd>MatlabRunToCell<CR>', 
                 { buffer = true, desc = 'Run to current MATLAB cell' })

    -- Breakpoints
    vim.keymap.set('n', prefix .. mappings.breakpoint, '<Cmd>MatlabBreakpoint<CR>', 
                 { buffer = true, desc = 'Set MATLAB breakpoint' })
    
    vim.keymap.set('n', prefix .. mappings.clear_breakpoint, '<Cmd>MatlabClearBreakpoint<CR>', 
                 { buffer = true, desc = 'Clear MATLAB breakpoint' })
    
    vim.keymap.set('n', prefix .. mappings.clear_breakpoints, '<Cmd>MatlabClearBreakpoints<CR>', 
                 { buffer = true, desc = 'Clear all MATLAB breakpoints' })

    -- Documentation
    vim.keymap.set('n', prefix .. mappings.doc, '<Cmd>MatlabDoc<CR>', 
                 { buffer = true, desc = 'Show MATLAB documentation' })

    -- Workspace
    vim.keymap.set('n', prefix .. mappings.toggle_workspace, '<Cmd>MatlabToggleWorkspace<CR>', 
                 { buffer = true, desc = 'Toggle MATLAB workspace window' })
    
    vim.keymap.set('n', prefix .. mappings.show_workspace, '<Cmd>MatlabWorkspace<CR>', 
                 { buffer = true, desc = 'Show MATLAB workspace in tmux' })
    
    vim.keymap.set('n', prefix .. mappings.clear_workspace, '<Cmd>MatlabClearWorkspace<CR>', 
                 { buffer = true, desc = 'Clear MATLAB workspace' })
    
    vim.keymap.set('n', prefix .. mappings.save_workspace, '<Cmd>MatlabSaveWorkspace<CR>', 
                 { buffer = true, desc = 'Save MATLAB workspace' })
    
    vim.keymap.set('n', prefix .. mappings.load_workspace, '<Cmd>MatlabLoadWorkspace<CR>', 
                 { buffer = true, desc = 'Load MATLAB workspace' })
    
    -- Cell folding
    vim.keymap.set('n', prefix .. mappings.toggle_cell_fold, '<Cmd>MatlabToggleCellFold<CR>', 
                 { buffer = true, desc = 'Toggle current MATLAB cell fold' })
    
    vim.keymap.set('n', prefix .. mappings.toggle_all_cell_folds, '<Cmd>MatlabToggleAllCellFolds<CR>', 
                 { buffer = true, desc = 'Toggle all MATLAB cell folds' })
    
    -- Additional mapping for commonly used functions using just the prefix
    vim.keymap.set('n', prefix, '<Cmd>MatlabRun<CR>', 
                 { buffer = true, desc = 'Run MATLAB script (shortcut)' })
  end
  
  -- ALWAYS add a non-leader backup mapping for testing
  vim.keymap.set('n', ',mr', '<Cmd>MatlabRun<CR>', 
               { buffer = true, desc = 'MATLAB Run (Fallback)' })
  
  -- Add command to view key mappings
  vim.api.nvim_buf_create_user_command(0, 'MatlabKeymaps', function()
    local lines = {"MATLAB key mappings:"}
    
    -- Show correct prefix based on leader
    local display_prefix = is_space_leader 
                        ? "Space" .. string.sub(prefix, 9) -- Remove <Leader> and add Space
                        : prefix
                        
    table.insert(lines, "- " .. display_prefix .. mappings.run .. " : Run MATLAB script")
    table.insert(lines, "- " .. display_prefix .. mappings.run_cell .. " : Run current MATLAB cell")
    table.insert(lines, "- " .. display_prefix .. mappings.run_to_cell .. " : Run to current MATLAB cell")
    table.insert(lines, "- " .. display_prefix .. mappings.breakpoint .. " : Set breakpoint")
    table.insert(lines, "- " .. display_prefix .. mappings.clear_breakpoint .. " : Clear breakpoint")
    table.insert(lines, "- " .. display_prefix .. mappings.doc .. " : Show documentation")
    table.insert(lines, "")
    table.insert(lines, "Fallback mapping: ,mr : Run MATLAB script")
    
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, {})
end

debug_info("MATLAB ftplugin setup complete")
