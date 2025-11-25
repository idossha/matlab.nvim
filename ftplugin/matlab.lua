-- ftplugin/matlab.lua

-- Only load this plugin once per buffer
if vim.b.did_ftplugin_matlab_nvim then
  return
end
vim.b.did_ftplugin_matlab_nvim = true

local config_status, config = pcall(require, 'matlab.config')
if not config_status then
  vim.notify("MATLAB: Failed to load matlab.config module. Check your installation.", vim.log.levels.ERROR)
  return
end

local utils_status, utils = pcall(require, 'matlab.utils')
if not utils_status then
  vim.notify("MATLAB: Failed to load matlab.utils module. Check your installation.", vim.log.levels.ERROR)
  return
end

-- Use centralized logging
utils.log("MATLAB ftplugin loading for buffer: " .. vim.api.nvim_buf_get_name(0), "DEBUG")

-- Get mappings config with better error handling
local function get_safe_mappings()
  local user_mappings = {}
  
  -- Try to get user mappings safely
  local status, result = pcall(function()
    return config.get('mappings')
  end)
  
  if status and type(result) == 'table' then
    user_mappings = result
    utils.log("Successfully loaded user mappings", "DEBUG")
  else
    utils.log("Failed to load user mappings, using defaults", "DEBUG")
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
    open_in_gui = 'g',
    -- Debug mappings
    debug_start = 'ds',
    debug_stop = 'de',
    debug_continue = 'dc',
    debug_step_over = 'do',
    debug_step_into = 'di',
    debug_step_out = 'dt',
    debug_toggle_breakpoint = 'db',
    debug_clear_breakpoints = 'dd',
    debug_ui = 'du',
    -- Debug UI mappings
    debug_show_variables = 'dv',
    debug_show_callstack = 'dk',
    debug_show_breakpoints = 'dp',
    debug_show_repl = 'dr',
    debug_toggle_variables = 'tv',
    debug_toggle_callstack = 'tk',
    debug_toggle_breakpoints = 'tp',
    debug_toggle_repl = 'tr',
    debug_close_ui = 'dx',
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

utils.log("Should set up mappings: " .. tostring(should_setup_mappings), "DEBUG")

if should_setup_mappings then
  local mappings = get_safe_mappings()
  local prefix = mappings.prefix or '<Leader>m'
  
  utils.log("Setting up MATLAB mappings with prefix: " .. prefix, "DEBUG")
  
  -- Helper function to create a mapping with proper error handling
  local function safe_map(lhs, rhs, desc)
    local status, error = pcall(function()
      vim.keymap.set('n', lhs, rhs, {buffer = true, desc = desc})
    end)
    
    if status then
      utils.log("Set mapping: " .. lhs .. " -> " .. rhs, "DEBUG")
    else
      utils.notify("Failed to set mapping: " .. lhs .. " - " .. tostring(error), vim.log.levels.ERROR, true)
    end
  end
  
  -- Get the actual prefix (Neovim handles <Leader> expansion internally)
  local actual_prefix = prefix
  
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
  safe_map(actual_prefix .. mappings.toggle_workspace, '<Cmd>MatlabWorkspace<CR>', 'Show MATLAB workspace (whos)')
  safe_map(actual_prefix .. mappings.clear_workspace, '<Cmd>MatlabClearWorkspace<CR>', 'Clear MATLAB workspace')
  safe_map(actual_prefix .. mappings.save_workspace, '<Cmd>MatlabSaveWorkspace<CR>', 'Save MATLAB workspace')
  safe_map(actual_prefix .. mappings.load_workspace, '<Cmd>MatlabLoadWorkspace<CR>', 'Load MATLAB workspace')

  -- Cell folding
  safe_map(actual_prefix .. mappings.toggle_cell_fold, '<Cmd>MatlabToggleCellFold<CR>', 'Toggle current MATLAB cell fold')
  safe_map(actual_prefix .. mappings.toggle_all_cell_folds, '<Cmd>MatlabToggleAllCellFolds<CR>', 'Toggle all MATLAB cell folds')

  -- Open in MATLAB GUI
  safe_map(actual_prefix .. mappings.open_in_gui, '<Cmd>MatlabOpenInGUI<CR>', 'Open in MATLAB GUI')

  -- Debug mappings
  safe_map(actual_prefix .. mappings.debug_start, '<Cmd>MatlabDebugStart<CR>', 'Start MATLAB debugging session')
  safe_map(actual_prefix .. mappings.debug_stop, '<Cmd>MatlabDebugStop<CR>', 'Stop MATLAB debugging session')
  safe_map(actual_prefix .. mappings.debug_continue, '<Cmd>MatlabDebugContinue<CR>', 'Continue MATLAB debugging')
  safe_map(actual_prefix .. mappings.debug_step_over, '<Cmd>MatlabDebugStepOver<CR>', 'Step over in MATLAB debugging')
  safe_map(actual_prefix .. mappings.debug_step_into, '<Cmd>MatlabDebugStepInto<CR>', 'Step into in MATLAB debugging')
  safe_map(actual_prefix .. mappings.debug_step_out, '<Cmd>MatlabDebugStepOut<CR>', 'Step out in MATLAB debugging')
  safe_map(actual_prefix .. mappings.debug_toggle_breakpoint, '<Cmd>MatlabDebugToggleBreakpoint<CR>', 'Toggle breakpoint in MATLAB debugging')
  safe_map(actual_prefix .. mappings.debug_clear_breakpoints, '<Cmd>MatlabDebugClearBreakpoints<CR>', 'Clear all breakpoints in MATLAB debugging')
  safe_map(actual_prefix .. mappings.debug_ui, '<Cmd>MatlabDebugUI<CR>', 'Show MATLAB debug UI')

  -- Debug UI mappings
  safe_map(actual_prefix .. mappings.debug_show_variables, '<Cmd>MatlabDebugShowVariables<CR>', 'Show MATLAB variables window')
  safe_map(actual_prefix .. mappings.debug_show_callstack, '<Cmd>MatlabDebugShowCallstack<CR>', 'Show MATLAB call stack window')
  safe_map(actual_prefix .. mappings.debug_show_breakpoints, '<Cmd>MatlabDebugShowBreakpoints<CR>', 'Show MATLAB breakpoints window')
  safe_map(actual_prefix .. mappings.debug_show_repl, '<Cmd>MatlabDebugShowRepl<CR>', 'Show MATLAB REPL window')
  safe_map(actual_prefix .. mappings.debug_toggle_variables, '<Cmd>MatlabDebugToggleVariables<CR>', 'Toggle MATLAB variables window')
  safe_map(actual_prefix .. mappings.debug_toggle_callstack, '<Cmd>MatlabDebugToggleCallstack<CR>', 'Toggle MATLAB call stack window')
  safe_map(actual_prefix .. mappings.debug_toggle_breakpoints, '<Cmd>MatlabDebugToggleBreakpoints<CR>', 'Toggle MATLAB breakpoints window')
  safe_map(actual_prefix .. mappings.debug_toggle_repl, '<Cmd>MatlabDebugToggleRepl<CR>', 'Toggle MATLAB REPL window')
  safe_map(actual_prefix .. mappings.debug_close_ui, '<Cmd>MatlabDebugCloseUI<CR>', 'Close all MATLAB debug UI windows')

  -- Always add a fallback mapping that doesn't depend on leader
  safe_map(',mr', '<Cmd>MatlabRun<CR>', 'Run MATLAB script (fallback)')
  
  -- Create a command to list all mappings
  vim.api.nvim_buf_create_user_command(0, 'MatlabKeymaps', function()
    local lines = {"MATLAB key mappings:"}
    
    -- Display prefix in a user-friendly way
    local display_prefix = vim.g.mapleader == " " and "Space" .. prefix:gsub("<Leader>", "") or prefix
    
    table.insert(lines, "- " .. display_prefix .. mappings.run .. " : Run MATLAB script")
    table.insert(lines, "- " .. display_prefix .. mappings.run_cell .. " : Run current MATLAB cell")
    table.insert(lines, "- " .. display_prefix .. mappings.run_to_cell .. " : Run to current MATLAB cell")
    table.insert(lines, "- " .. display_prefix .. mappings.breakpoint .. " : Set breakpoint")
    table.insert(lines, "- " .. display_prefix .. mappings.clear_breakpoint .. " : Clear breakpoint")
    table.insert(lines, "- " .. display_prefix .. mappings.clear_breakpoints .. " : Clear all breakpoints")
    table.insert(lines, "- " .. display_prefix .. mappings.doc .. " : Show documentation")
    table.insert(lines, "- " .. display_prefix .. mappings.toggle_workspace .. " : Show workspace (whos)")
    table.insert(lines, "- " .. display_prefix .. mappings.open_in_gui .. " : Open in MATLAB GUI")
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
    utils.log("Verified " .. keymap_count .. " MATLAB mappings were set", "DEBUG")
  end, 100)
end

utils.log("MATLAB ftplugin setup complete", "DEBUG")
