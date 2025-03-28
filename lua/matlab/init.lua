-- Main module for matlab.nvim
-- lua/matlab/init.lua
local M = {}
local config = require('matlab.config')
local tmux = require('matlab.tmux')
local commands = require('matlab.commands')
local cells = require('matlab.cells')
local workspace = require('matlab.workspace')

-- Improved notification function that respects settings
local function notify(message, level, force)
  level = level or vim.log.levels.INFO
  
  -- Only show if minimal_notifications is false or this is a critical error
  if not config.get('minimal_notifications') or force or level == vim.log.levels.ERROR then
    vim.notify(message, level)
  end
  
  -- Always log to file for debugging
  local log_file = io.open(vim.fn.stdpath('cache') .. '/matlab_nvim.log', 'a')
  if log_file then
    log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. message .. "\n")
    log_file:close()
  end
end

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
    if not config.get('minimal_notifications') then
      notify("matlab.nvim loaded successfully. Use :MatlabStartServer to start MATLAB.")
    end
  end)
  
  -- Pass the notify function to the modules that need it
  if tmux.set_notify_function then
    tmux.set_notify_function(notify)
  end
  
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
    local ui_settings = {
      ["Panel Size"] = config.get('panel_size'),
      ["Panel Size Type"] = config.get('panel_size_type'),
      ["TMUX Pane Direction"] = config.get('tmux_pane_direction'),
      ["TMUX Pane Focus"] = config.get('tmux_pane_focus'),
      ["Auto Start"] = config.get('auto_start'),
      ["Default Mappings"] = config.get('default_mappings'),
      ["Debug Mode"] = config.get('debug'),
      ["Minimal Notifications"] = config.get('minimal_notifications'),
      ["MATLAB Executable"] = config.get('executable')
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
    -- Add a command to view .mat files
  vim.api.nvim_create_user_command('MatlabViewMat', function(opts)
    local file_path = opts.args
    if file_path == "" then
      file_path = vim.fn.expand('%:p')
    end
    require('matlab.matfile').view_mat_file(file_path)
  end, {nargs = '?', complete = 'file'})
  
  -- Log configuration after setup
  if config.get('debug') then
    local debug_settings = {
      "MATLAB.nvim configuration:",
      "- executable: " .. config.get('executable'),
      "- panel_size: " .. config.get('panel_size'),
      "- panel_size_type: " .. config.get('panel_size_type'),
      "- tmux_pane_direction: " .. config.get('tmux_pane_direction'),
      "- auto_start: " .. tostring(config.get('auto_start')),
      "- default_mappings: " .. tostring(config.get('default_mappings')),
      "- debug: " .. tostring(config.get('debug')),
      "- minimal_notifications: " .. tostring(config.get('minimal_notifications'))
    }
    
    -- Log to file only, don't notify
    local log_file = io.open(vim.fn.stdpath('cache') .. '/matlab_nvim.log', 'a')
    if log_file then
      for _, line in ipairs(debug_settings) do
        log_file:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. line .. "\n")
      end
      log_file:close()
    end
  end
end





-- Export submodules
M.commands = commands
M.cells = cells
M.workspace = workspace
M.tmux = tmux
M.config = config
M.matfile = require('matlab.matfile')

return M
