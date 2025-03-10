-- Example configuration for matlab.nvim
-- Copy this file to your Neovim config directory and require it

return {
  'idossha/matlab.nvim',
  ft = 'matlab',
  config = function()
    require('matlab').setup({
      -- Path to MATLAB executable (should be full path)
      executable = '/Applications/MATLAB_R2023b.app/bin/matlab',  -- Adjust for your MATLAB version
      
      -- Behavior options
      auto_start = true,                -- Auto-start MATLAB when opening a .m file
      default_mappings = true,          -- Enable default keymappings
      
      -- Uncomment to customize keymappings
      -- mappings = {
      --   prefix = '<Leader>m',        -- Common prefix for all MATLAB mappings
      --   run = 'r',                   -- Run MATLAB script  
      --   run_cell = 'c',              -- Run current MATLAB cell
      --   run_to_cell = 't',           -- Run to current MATLAB cell
      --   breakpoint = 'b',            -- Set breakpoint at current line
      --   clear_breakpoint = 'd',      -- Clear breakpoint in current file
      --   clear_breakpoints = 'D',     -- Clear all breakpoints
      --   doc = 'h',                   -- Show documentation for word under cursor
      --   toggle_workspace = 'w',      -- Toggle workspace floating window
      --   show_workspace = 'W',        -- Show MATLAB workspace in tmux pane
      --   clear_workspace = 'x',       -- Clear MATLAB workspace
      --   save_workspace = 's',        -- Save MATLAB workspace
      --   load_workspace = 'l',        -- Load MATLAB workspace
      --   toggle_cell_fold = 'f',      -- Toggle current cell fold
      --   toggle_all_cell_folds = 'F', -- Toggle all cell folds
      -- },
    })
  end
}