-- Commands for matlab.nvim
local M = {}
local tmux = require('matlab.tmux')

-- Check if the current buffer is a MATLAB script
function M.is_matlab_script()
  local filetype = vim.bo.filetype
  if filetype == 'matlab' or filetype == 'octave' then
    return true
  end
  vim.notify('Not a MATLAB script.', vim.log.levels.WARN)
  return false
end

-- Get the MATLAB filename (without extension)
function M.get_filename()
  return vim.fn.expand('%:t'):gsub('%.m', '')
end

-- Run a MATLAB script
function M.run(command)
  if not tmux.exists() then
    return
  end

  if command then
    tmux.run(command)
  else
    -- Make sure that this is actually a MATLAB script
    if not M.is_matlab_script() then
      return
    end
    
    -- Check if buffer is modifiable and can be written
    if not vim.bo.modifiable then
      vim.notify('Buffer is not modifiable', vim.log.levels.ERROR)
      return
    end
    
    -- Only write if buffer is modified or if file doesn't exist
    if vim.bo.modified or vim.fn.filereadable(vim.fn.expand('%')) ~= 1 then
      local ok, err = pcall(vim.cmd, 'write')
      if not ok then
        vim.notify('Failed to save file: ' .. tostring(err), vim.log.levels.ERROR)
        return
      end
    end
    
    tmux.run(M.get_filename())
  end
end

-- Open current script in MATLAB GUI
function M.open_in_gui()
  if not M.is_matlab_script() then
    return
  end
  
  -- Save file before opening in GUI
  if vim.bo.modified then
    local ok, err = pcall(vim.cmd, 'write')
    if not ok then
      vim.notify('Failed to save file: ' .. tostring(err), vim.log.levels.ERROR)
      return
    end
  end
  
  local filepath = vim.fn.expand('%:p')
  if filepath == '' or vim.fn.filereadable(filepath) ~= 1 then
    vim.notify('File does not exist or is not readable', vim.log.levels.ERROR)
    return
  end
  
  local executable = require('matlab.config').get('executable')
  
  -- Build a system command to open the file directly in MATLAB
  local cmd
  if vim.fn.has('mac') == 1 then
    cmd = executable .. ' -desktop -r "edit ' .. filepath .. '"'
  elseif vim.fn.has('win32') == 1 or vim.fn.has('win64') == 1 then
    cmd = executable .. ' /desktop /r "edit ' .. filepath .. '"'
  else -- Linux/WSL
    -- Note: This opens in GUI mode (doesn't use -nodesktop flag)
    -- DISPLAY will be inherited from the parent environment, not from the tmux pane
    cmd = executable .. ' -desktop -r "edit ' .. filepath .. '"'
  end
  
  -- Execute the command in the background
  -- This spawns a new MATLAB process separate from the tmux CLI instance
  vim.fn.jobstart(cmd)
end

-- Run all tests using runtests(pwd)
function M.run_tests()
  if not tmux.exists() then
    return
  end
  tmux.run('runtests(pwd)')
end

-- Run the test at cursor
function M.run_current_test()
  if not tmux.exists() then
    return
  end

  -- Ensure we are in a MATLAB buffer
  if not M.is_matlab_script() then
    return
  end

  -- Try to get the parser for the current buffer
  local has_parser, parser = pcall(vim.treesitter.get_parser, 0, "matlab")
  if not has_parser or not parser then
    vim.notify('MATLAB Tree-sitter parser not found. Please run :TSInstall matlab', vim.log.levels.ERROR)
    return
  end

  -- Get the root of the tree
  local tree = parser:parse()[1]
  local root = tree:root()
  
  -- Get the node at the cursor
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local node = root:named_descendant_for_range(row, col, row, col)

  if not node then
    vim.notify('No syntax node found at cursor position.', vim.log.levels.WARN)
    return
  end

  local function_name = nil
  local class_name = nil

  -- Traverse up to find Function or Class definition
  local curr = node
  while curr do
    local type = curr:type()
    if type == "function_definition" then
      -- In many parsers, name is a field. We can use field() to check.
      -- However, iterating children and checking their field name is safer
      -- for different parser versions.
      for child, field in curr:iter_children() do
        if field == "name" then
          function_name = vim.treesitter.get_node_text(child, 0)
          break
        end
      end
      -- Fallback if field "name" wasn't found (though it should be)
      if not function_name then
        for child in curr:iter_children() do
          if child:type() == "identifier" then
             function_name = vim.treesitter.get_node_text(child, 0)
             break
          end
        end
      end
    elseif type == "classdef" then
      for child, field in curr:iter_children() do
        if field == "name" then
          class_name = vim.treesitter.get_node_text(child, 0)
          break
        end
      end
    end
    curr = curr:parent()
  end

  local test_cmd = nil
  local filename = M.get_filename()

  if function_name then
    -- It's a method or a function
    if class_name then
      -- Class-based test
      test_cmd = string.format("runtests('%s/%s')", class_name, function_name)
    else
      -- Function-based test (or just a local function in a test file)
      test_cmd = string.format("runtests('%s/%s')", filename, function_name)
    end
  elseif class_name then
    -- Just the class
    test_cmd = string.format("runtests('%s')", class_name)
  else
    -- Fallback to running the whole file as a test
    test_cmd = string.format("runtests('%s')", filename)
  end

  if test_cmd then
    vim.notify('Running test: ' .. test_cmd, vim.log.levels.INFO)
    tmux.run(test_cmd)
  end
end

-- Show documentation for the word under cursor
function M.doc()
  if not tmux.exists() then
    return
  end

  return tmux.run('help ' .. vim.fn.expand('<cword>'), true, true)
end

return M