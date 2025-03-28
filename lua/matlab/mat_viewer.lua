-- lua/matlab/mat_viewer.lua
local M = {}
local config = require('matlab.config')
local utils = require('matlab.utils') -- We'll use it if it exists, or create placeholder functions

-- Define utility functions if they don't exist
if not utils then
  utils = {}
  utils.notify = function(message, level)
    vim.notify("MATLAB MAT-Viewer: " .. message, level or vim.log.levels.INFO)
  end
end

-- Path to Python script for MAT-file conversion
local script_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/matlab.nvim/scripts/mat_to_text.py'

-- Ensure the scripts directory exists
local function ensure_script_dir()
  local script_dir = vim.fn.fnamemodify(script_path, ':h')
  if vim.fn.isdirectory(script_dir) ~= 1 then
    vim.fn.mkdir(script_dir, 'p')
  end
end

-- Write the Python script to disk if it doesn't exist
local function ensure_script_exists()
  ensure_script_dir()
  if vim.fn.filereadable(script_path) ~= 1 then
    local file = io.open(script_path, 'w')
    if file then
      file:write([[
import sys
import json
import numpy as np
import os

# Check if scipy is available
try:
    import scipy.io
except ImportError:
    print("Error: scipy module is required for MAT file parsing.")
    print("Please install it with: pip install scipy")
    sys.exit(1)

# Custom JSON encoder to handle NumPy types
class NumpyEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, np.ndarray):
            return obj.tolist()
        if isinstance(obj, np.integer):
            return int(obj)
        if isinstance(obj, np.floating):
            return float(obj)
        if isinstance(obj, np.bool_):
            return bool(obj)
        if isinstance(obj, np.complex_):
            return {'real': obj.real, 'imag': obj.imag}
        return super(NumpyEncoder, self).default(obj)

def mat_to_text(filename, output_format='json'):
    try:
        # Check if a previous conversion exists
        output_filename = filename + '.json'
        if os.path.exists(output_filename) and os.path.getmtime(output_filename) > os.path.getmtime(filename):
            print(f"Using existing converted file: {output_filename}")
            return output_filename
            
        # Load the MAT file
        mat_contents = scipy.io.loadmat(filename)
        
        # Remove metadata entries (keys that start with '__')
        filtered_contents = {k: v for k, v in mat_contents.items() if not k.startswith('__')}
        
        # Convert to JSON
        json_str = json.dumps(filtered_contents, cls=NumpyEncoder, indent=2)
        
        # Save to a text file
        with open(output_filename, 'w') as f:
            f.write(json_str)
        
        print(f"Successfully converted {filename} to {output_filename}")
        return output_filename
        
    except Exception as e:
        print(f"Error processing {filename}: {e}")
        return None

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python mat_to_text.py your_file.mat")
    else:
        mat_to_text(sys.argv[1])
]])
      file:close()
      utils.notify("Created MAT-file conversion script", vim.log.levels.INFO)
    else
      utils.notify("Failed to create MAT-file conversion script", vim.log.levels.ERROR)
    end
  end
end

-- Check if Python and required packages are available
local function check_python_deps()
  local has_python = vim.fn.executable('python3') == 1 or vim.fn.executable('python') == 1
  if not has_python then
    utils.notify("Python not found. Please install Python for MAT-file conversion", vim.log.levels.ERROR)
    return false
  end
  
  -- We'll check for scipy when running the script
  return true
end

-- Convert MAT file to readable format
function M.convert_mat_file(mat_file)
  ensure_script_exists()
  
  if not check_python_deps() then
    return nil
  end
  
  -- Determine python command
  local python_cmd = vim.fn.executable('python3') == 1 and 'python3' or 'python'
  
  -- Run the conversion script
  local cmd = string.format('%s %s "%s"', python_cmd, script_path, mat_file)
  local output = vim.fn.system(cmd)
  
  -- Check for errors
  if vim.v.shell_error ~= 0 then
    utils.notify("Error converting MAT-file: " .. output, vim.log.levels.ERROR)
    return nil
  end
  
  -- Find the output filename from the script's output
  local output_file = string.match(output, "Successfully converted .* to (.*)")
  if not output_file then
    -- Check if we're using an existing conversion
    output_file = string.match(output, "Using existing converted file: (.*)")
  end
  
  if output_file then
    output_file = output_file:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
    return output_file
  else
    utils.notify("Failed to determine output file", vim.log.levels.ERROR)
    return nil
  end
end

-- Open MAT file in readable format
function M.open_mat_file(mat_file)
  local converted_file = M.convert_mat_file(mat_file)
  if converted_file then
    -- Open the converted file in the current buffer
    vim.cmd('edit ' .. vim.fn.fnameescape(converted_file))
    
    -- Set filetype for syntax highlighting
    vim.bo.filetype = 'json'
    
    -- Add header with info about the original MAT file
    local lines = {
      '// Converted from MAT-file: ' .. mat_file,
      '// To reload after MAT-file changes, use :MatlabReloadMatFile',
      '//'
    }
    vim.api.nvim_buf_set_lines(0, 0, 0, false, lines)
    
    -- Mark buffer as read-only to prevent accidental edits
    vim.bo.readonly = true
    vim.bo.modifiable = false
    
    utils.notify("Opened converted MAT-file", vim.log.levels.INFO)
    return true
  else
    utils.notify("Failed to open MAT-file", vim.log.levels.ERROR)
    return false
  end
end

-- Reload the current MAT file
function M.reload_mat_file()
  -- Get the current buffer's content to find the original MAT file
  local lines = vim.api.nvim_buf_get_lines(0, 0, 1, false)
  if #lines > 0 then
    local mat_file = string.match(lines[1], '// Converted from MAT%-file: (.*)')
    if mat_file then
      -- Make buffer modifiable to update content
      vim.bo.readonly = false
      vim.bo.modifiable = true
      
      -- Convert and reload
      local converted_file = M.convert_mat_file(mat_file)
      if converted_file then
        -- Read the file content
        local file = io.open(converted_file, 'r')
        if file then
          local content = file:read("*all")
          file:close()
          
          -- Replace buffer content with new content, preserving header
          local header_lines = vim.api.nvim_buf_get_lines(0, 0, 3, false)
          local content_lines = vim.split(content, '\n')
          
          vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
          vim.api.nvim_buf_set_lines(0, 0, 0, false, header_lines)
          vim.api.nvim_buf_set_lines(0, 3, 3, false, content_lines)
          
          -- Reset buffer properties
          vim.bo.readonly = true
          vim.bo.modifiable = false
          
          utils.notify("Reloaded MAT-file", vim.log.levels.INFO)
          return true
        end
      end
    end
  end
  
  utils.notify("Could not reload MAT-file - not viewing a converted MAT-file", vim.log.levels.ERROR)
  return false
end

-- Set up autocommands for MAT file handling
function M.setup()
  local augroup = vim.api.nvim_create_augroup('matlab_mat_viewer', { clear = true })
  
  -- Intercept attempts to open MAT files
  vim.api.nvim_create_autocmd({"BufReadPre"}, {
    group = augroup,
    pattern = {"*.mat"},
    callback = function(args)
      -- Stop the normal file reading
      vim.cmd("silent! let &undolevels = &undolevels")
      -- Open the converted version instead
      vim.schedule(function()
        M.open_mat_file(args.match)
      end)
    end
  })
  
  -- Create user commands
  vim.api.nvim_create_user_command('MatlabOpenMatFile', function(opts)
    M.open_mat_file(opts.args)
  end, { nargs = 1, complete = 'file' })
  
  vim.api.nvim_create_user_command('MatlabReloadMatFile', function()
    M.reload_mat_file()
  end, {})
  
  utils.notify("MAT-file viewer initialized", vim.log.levels.INFO)
end

return M
