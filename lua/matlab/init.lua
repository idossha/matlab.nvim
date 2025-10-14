-- Main module for matlab.nvim
-- lua/matlab/init.lua
local M = {}
local config = require('matlab.config')
local utils = require('matlab.utils')
local tmux = require('matlab.tmux')
local commands = require('matlab.commands')
local cells = require('matlab.cells')
local workspace = require('matlab.workspace')

-- Use centralized notification system
local notify = utils.notify

-- Define the breakpoint sign with custom highlight groups
local function define_signs()
  -- Create a custom highlight group for breakpoints if it doesn't exist
  vim.api.nvim_command('highlight default MatlabBreakpoint guifg=#ff0000 guibg=#5a0000 ctermfg=196 ctermbg=52 gui=bold cterm=bold')
  vim.api.nvim_command('highlight default MatlabBreakpointLine guibg=#300000 ctermbg=235')
  
  -- Get user breakpoint config
  local bp_config = config.get('breakpoint') or {}
  
  -- Define the sign with the user's custom or default settings
  vim.fn.sign_define('matlab_breakpoint', {
    text = bp_config.sign_text or '■',
    texthl = bp_config.sign_hl or 'MatlabBreakpoint',
    linehl = bp_config.line_hl or 'MatlabBreakpointLine',
    numhl = bp_config.num_hl or 'MatlabBreakpoint'
  })
end

-- Setup function
function M.setup(opts)
  -- Set default options
  local defaults = {
    force_nogui_with_breakpoints = true, -- Prevent GUI from opening when breakpoints exist
  }
  
  -- Merge with user options
  opts = opts or {}
  for k, v in pairs(defaults) do
    if opts[k] == nil then
      opts[k] = v
    end
  end
  
  -- Initialize configuration
  config.setup(opts)
  
  -- Define signs for breakpoints
  define_signs()
  
  -- Show message on first load only if minimal notifications are disabled
  vim.schedule(function()
    notify("matlab.nvim loaded successfully. Use :MatlabStartServer to start MATLAB.")
  end)
  
  -- Create user commands
  vim.api.nvim_create_user_command('MatlabRun', function(args)
    commands.run(args.args ~= '' and args.args or nil)
  end, { nargs = '?' })
  
  vim.api.nvim_create_user_command('MatlabBreakpoint', function()
    commands.single_breakpoint()
  end, {})
  
  vim.api.nvim_create_user_command('MatlabStartServer', function()
    tmux.start_server(false)
  end, {})
  
  vim.api.nvim_create_user_command('MatlabAutoStartServer', function()
    tmux.start_server(true)
  end, {})
  
  vim.api.nvim_create_user_command('MatlabStopServer', function()
    tmux.stop_server()
  end, {})
  
  vim.api.nvim_create_user_command('MatlabClearBreakpoint', function()
    commands.clear_breakpoint(false)
  end, {})
  
  vim.api.nvim_create_user_command('MatlabClearBreakpoints', function()
    commands.clear_breakpoint(true)
  end, {})
  
  -- New command to open in MATLAB GUI
  vim.api.nvim_create_user_command('MatlabOpenInGUI', function()
    commands.open_in_gui()
  end, {})
  
  vim.api.nvim_create_user_command('MatlabDoc', function()
    commands.doc()
  end, {})
  
  -- Cell execution commands
  vim.api.nvim_create_user_command('MatlabRunCell', function()
    cells.execute_current_cell()
  end, {})
  
  vim.api.nvim_create_user_command('MatlabRunToCell', function()
    cells.execute_to_cell()
  end, {})
  
  -- Cell folding commands
  vim.api.nvim_create_user_command('MatlabToggleCellFold', function()
    cells.toggle_cell_fold()
  end, {})
  
  vim.api.nvim_create_user_command('MatlabToggleAllCellFolds', function()
    cells.toggle_all_cell_folds()
  end, {})
  
  -- Workspace commands
  vim.api.nvim_create_user_command('MatlabWorkspace', function()
    workspace.show()
  end, {})
  
  vim.api.nvim_create_user_command('MatlabToggleWorkspace', function()
    workspace.toggle()
  end, {})
  
  vim.api.nvim_create_user_command('MatlabClearWorkspace', function()
    workspace.clear()
  end, {})
  
  vim.api.nvim_create_user_command('MatlabSaveWorkspace', function(args)
    workspace.save(args.args ~= '' and args.args or nil)
  end, { nargs = '?' })
  
  vim.api.nvim_create_user_command('MatlabLoadWorkspace', function(args)
    workspace.load(args.args ~= '' and args.args or nil)
  end, { nargs = '?' })
  
  -- Debug command to check UI settings
  vim.api.nvim_create_user_command('MatlabDebugUI', function()
    local env_vars = config.get('environment')
    local env_display = "None"
    if env_vars and next(env_vars) then
      local env_parts = {}
      for k, v in pairs(env_vars) do
        table.insert(env_parts, k .. '=' .. tostring(v))
      end
      env_display = table.concat(env_parts, ', ')
    end
    
    local ui_settings = {
      ["Panel Size"] = config.get('panel_size'),
      ["Panel Size Type"] = config.get('panel_size_type'),
      ["TMUX Pane Direction"] = config.get('tmux_pane_direction'),
      ["TMUX Pane Focus"] = config.get('tmux_pane_focus'),
      ["Auto Start"] = config.get('auto_start'),
      ["Default Mappings"] = config.get('default_mappings'),
      ["Debug Mode"] = config.get('debug'),
      ["Minimal Notifications"] = config.get('minimal_notifications'),
      ["MATLAB Executable"] = config.get('executable'),
      ["Environment Variables"] = env_display
    }
    
    local lines = {"MATLAB UI Settings:"}
    for k, v in pairs(ui_settings) do
      table.insert(lines, "- " .. k .. ": " .. tostring(v))
    end
    
    vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
  end, {})
  
  -- Set up autocommands
  vim.api.nvim_create_augroup('matlab_nvim', { clear = true })
  
  -- Autostart MATLAB when opening a .m file
  vim.api.nvim_create_autocmd('FileType', {
    group = 'matlab_nvim',
    pattern = 'matlab',
    callback = function()
      -- Only if auto_start is enabled
      if config.get('auto_start') then
        vim.cmd('MatlabAutoStartServer')
      end
    end,
  })
  
  -- Stop MATLAB when exiting Neovim
  vim.api.nvim_create_autocmd('VimLeave', {
    group = 'matlab_nvim',
    callback = function()
      vim.cmd('MatlabStopServer')
    end,
  })
  
  -- Log configuration after setup
  if config.get('debug') then
    local env_vars = config.get('environment')
    local env_debug = "None"
    if env_vars and next(env_vars) then
      local env_parts = {}
      for k, v in pairs(env_vars) do
        table.insert(env_parts, k .. '=' .. tostring(v))
      end
      env_debug = table.concat(env_parts, ', ')
    end
    
    utils.log("MATLAB.nvim configuration:", "INFO")
    utils.log("- executable: " .. config.get('executable'), "INFO")
    utils.log("- panel_size: " .. config.get('panel_size'), "INFO")
    utils.log("- panel_size_type: " .. config.get('panel_size_type'), "INFO")
    utils.log("- tmux_pane_direction: " .. config.get('tmux_pane_direction'), "INFO")
    utils.log("- auto_start: " .. tostring(config.get('auto_start')), "INFO")
    utils.log("- default_mappings: " .. tostring(config.get('default_mappings')), "INFO")
    utils.log("- debug: " .. tostring(config.get('debug')), "INFO")
    utils.log("- minimal_notifications: " .. tostring(config.get('minimal_notifications')), "INFO")
    utils.log("- environment: " .. env_debug, "INFO")
  end
end

-- Export submodules
M.commands = commands
M.cells = cells
M.workspace = workspace
M.tmux = tmux
M.config = config

return M
