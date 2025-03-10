-- Save this as ftplugin/matlab.lua (replacing your current version)

-- Only load this plugin once per buffer
if vim.b.did_ftplugin_matlab_nvim then
  return
end
vim.b.did_ftplugin_matlab_nvim = true

local config_status, config = pcall(require, 'matlab.config')
if not config_status then
  -- Handle the case where config module couldn't be loaded
  vim.notify("MATLAB: Failed to load matlab.config module. Check your installation.", vim.log.levels.ERROR)
  return
end

-- Enhanced debug function that respects configuration settings
local function debug_info(message, force)
  -- Only print messages if debug is enabled or it's a forced message
  if config.get('debug') or force then
    -- Only show notifications if minimal_notifications is false or it's a forced message
    if not config.get('minimal_notifications') or force then
      vim.notify("MATLAB: " .. message, vim.log.levels.INFO)
    end
  end
  
  -- Always log to a file for debugging (regardless of settings)
  local log_file = io.open(vim.fn.stdpath('cache') .. '/matlab_nvim.log', 'a')
  if log_file then
    log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. message .. "\n")
    log_file:close()
  end
end

-- Important startup message but doesn't need to be shown to user
debug_info("MATLAB ftplugin loading for buffer: " .. vim.api.nvim_buf_get_name(0))

-- Get mappings config with better error handling
local function get_safe_mappings()
  local user_mappings = {}
  
  -- Try to get user mappings safely
  local status, result = pcall(function() 
    return config.get('mappings') 
  end)
  
  if status and type(result) == 'table' then
    user_mappings = result
    debug_info("Successfully loaded user mappings")
  else
    debug_info("Failed to load user mappings, using defaults")
  end
  
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
  
  -- Merge with defaults
  for k, v in pairs(default_mappings) do
    if user_mappings[k] == nil then
      user_mappings[k] = v
    end
  end
  
  return user_mappings
end

-- Should we set up mappings?
local should_setup_mappings = true
local status, result = pcall(function() 
  return config.get('default_mappings') 
end)

if status then
  should_setup_mappings = result
end

debug_info("Should set up mappings: " .. tostring(should_setup_mappings))

if should_setup_mappings then
  local mappings = get_safe_mappings()
  local prefix = mappings.prefix or '<Leader>m'
  
  debug_info("Setting up MATLAB mappings with prefix: " .. prefix)
  debug_info("mapleader = '" .. (vim.g.mapleader or '\\') .. "'")
  
  -- Check if leader is a space
  local is_space_leader = vim.g.mapleader == " "
  debug_info("Space leader: " .. tostring(is_space_leader))
  
  -- Helper function to create a mapping with proper error handling
  local function safe_map(lhs, rhs, desc)
    local status, error = pcall(function()
      vim.keymap.set('n', lhs, rhs, {buffer = true, desc = desc})
    end)
    
    if status then
      debug_info("Set mapping: " .. lhs .. " -> " .. rhs)
    else
      debug_info("Failed to set mapping: " .. lhs .. " - " .. tostring(error), true) -- Force important errors
    end
  end
  
  -- Use explicit space in mappings when leader is space
  local actual_prefix
  if is_space_leader then
    -- Replace <Leader> with an actual space
    actual_prefix = prefix:gsub("<Leader>", " ")
    debug_info("Using explicit space prefix: '" .. actual_prefix .. "'")
  else
    actual_prefix = prefix
  end
  
  -- Set all the mappings using the correct prefix
  -- Run commands
  safe_map(actual_prefix .. mappings.run, '<Cmd>MatlabRun<CR>', 'Run MATLAB script')
  safe_map(actual_prefix .. mappings.run_cell, '<Cmd>MatlabRunCell<CR>', 'Run current MATLAB cell')
  safe_map(actual_prefix .. mappings.run_to_cell, '<Cmd>MatlabRunToCell<CR>', 'Run to current MATLAB cell')

  -- Breakpoints
  safe_map(actual_prefix .. mappings.breakpoint, '<Cmd>MatlabBreakpoint<CR>', 'Set MATLAB breakpoint')
  safe_map(actual_prefix .. mappings.clear_breakpoint, '<Cmd>MatlabClearBreakpoint<CR>', 'Clear MATLAB breakpoint')
  safe_map(actual_prefix .. mappings.clear_breakpoints, '<Cmd>MatlabClearBreakpoints<CR>', 'Clear all MATLAB breakpoints')

  -- Documentation
  safe_map(actual_prefix .. mappings.doc, '<Cmd>MatlabDoc<CR>', 'Show MATLAB documentation')

  -- Workspace
  safe_map(actual_prefix .. mappings.toggle_workspace, '<Cmd>MatlabToggleWorkspace<CR>', 'Toggle MATLAB workspace window')
  safe_map(actual_prefix .. mappings.show_workspace, '<Cmd>MatlabWorkspace<CR>', 'Show MATLAB workspace in tmux')
  safe_map(actual_prefix .. mappings.clear_workspace, '<Cmd>MatlabClearWorkspace<CR>', 'Clear MATLAB workspace')
  safe_map(actual_prefix .. mappings.save_workspace, '<Cmd>MatlabSaveWorkspace<CR>', 'Save MATLAB workspace')
  safe_map(actual_prefix .. mappings.load_workspace, '<Cmd>MatlabLoadWorkspace<CR>', 'Load MATLAB workspace')

  -- Cell folding
  safe_map(actual_prefix .. mappings.toggle_cell_fold, '<Cmd>MatlabToggleCellFold<CR>', 'Toggle current MATLAB cell fold')
  safe_map(actual_prefix .. mappings.toggle_all_cell_folds, '<Cmd>MatlabToggleAllCellFolds<CR>', 'Toggle all MATLAB cell folds')

  -- Additional mapping for commonly used functions using just the prefix
  safe_map(actual_prefix, '<Cmd>MatlabRun<CR>', 'Run MATLAB script (shortcut)')
  
  -- Always add a fallback mapping that doesn't depend on leader
  safe_map(',mr', '<Cmd>MatlabRun<CR>', 'Run MATLAB script (fallback)')
  
  -- Create a command to list all mappings
  vim.api.nvim_buf_create_user_command(0, 'MatlabKeymaps', function()
    local lines = {"MATLAB key mappings:"}
    
    -- Display prefix in a user-friendly way
    local display_prefix = is_space_leader and "Space" .. actual_prefix:sub(2) or actual_prefix
    
    table.insert(lines, "- " .. display_prefix .. mappings.run .. " : Run MATLAB script")
    table.insert(lines, "- " .. display_prefix .. mappings.run_cell .. " : Run current MATLAB cell")
    table.insert(lines, "- " .. display_prefix .. mappings.run_to_cell .. " : Run to current MATLAB cell")
    table.insert(lines, "- " .. display_prefix .. mappings.breakpoint .. " : Set breakpoint")
    table.insert(lines, "- " .. display_prefix .. mappings.clear_breakpoint .. " : Clear breakpoint")
    table.insert(lines, "- " .. display_prefix .. mappings.clear_breakpoints .. " : Clear all breakpoints")
    table.insert(lines, "- " .. display_prefix .. mappings.doc .. " : Show documentation")
    table.insert(lines, "")
    table.insert(lines, "Fallback mapping: ,mr : Run MATLAB script")
    
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, {})
  
  -- Check if the mappings were successfully set (only log, don't notify)
  vim.defer_fn(function()
    local keymap_count = 0
    for _, map in ipairs(vim.api.nvim_buf_get_keymap(0, 'n')) do
      if map.desc and map.desc:find("MATLAB") then
        keymap_count = keymap_count + 1
      end
    end
    debug_info("Verified " .. keymap_count .. " MATLAB mappings were set")
  end, 100)
end

debug_info("MATLAB ftplugin setup complete")
