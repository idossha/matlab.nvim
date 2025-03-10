-- Save as diagnostic-matlab.lua
-- Comprehensive MATLAB.nvim diagnostic script

local function log(msg)
  print(msg)
end

log("===== MATLAB.nvim Diagnostic Report =====")

-- Test 1: Check runtime paths
log("\n1. Runtime paths:")
local rtps = vim.opt.runtimepath:get()
local found_matlab = false
for i, path in ipairs(rtps) do
  if path:find("matlab%.nvim") then
    log("✓ Found matlab.nvim in runtimepath at position " .. i .. ": " .. path)
    found_matlab = true
  end
end

if not found_matlab then
  log("✗ matlab.nvim not found in runtimepath!")
  log("First 3 runtime paths:")
  for i=1, math.min(3, #rtps) do
    log("  " .. i .. ": " .. rtps[i])
  end
end

-- Test 2: Check for key files
log("\n2. Key files:")
local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

local plugin_dir = vim.fn.fnamemodify(vim.fn.expand('$MYVIMRC'), ':h') .. '/matlab.nvim'
if not file_exists(plugin_dir .. '/lua/matlab/init.lua') then
  plugin_dir = '.'  -- Try current directory
end

local files_to_check = {
  "/ftplugin/matlab.lua",
  "/ftplugin/matlab.vim",
  "/lua/matlab/init.lua",
  "/lua/matlab/config.lua"
}

for _, file in ipairs(files_to_check) do
  local full_path = plugin_dir .. file
  log(file .. ": " .. (file_exists(full_path) and "✓ exists" or "✗ not found") .. 
    " at " .. full_path)
end

-- Test 3: Test module loading
log("\n3. Module loading:")
local modules = {
  "matlab",
  "matlab.config",
  "matlab.commands",
  "matlab.cells"
}

for _, module in ipairs(modules) do
  local status, result = pcall(require, module)
  log(module .. ": " .. (status and "✓ loaded" or "✗ error: " .. tostring(result)))
  
  -- If config loaded successfully, check settings
  if status and module == "matlab.config" then
    log("  - default_mappings: " .. tostring(result.get('default_mappings')))
    log("  - debug: " .. tostring(result.get('debug')))
    log("  - mappings.prefix: " .. tostring(result.get('mappings').prefix))
  end
end

-- Test 4: Check filetype detection
log("\n4. Filetype detection:")
vim.cmd([[
  silent! edit! test_temp.m
]])

log("Filetype for .m file: '" .. vim.bo.filetype .. "'")
if vim.bo.filetype ~= "matlab" then
  log("✗ .m files not detected as matlab filetype!")
end

-- Test 5: Check ftplugin loading
log("\n5. Ftplugin loading:")
local function check_matlab_ftplugin()
  -- Make a new buffer and set filetype to matlab manually
  vim.cmd('enew')
  vim.bo.filetype = 'matlab'
  
  -- Check if our flag is set
  if vim.b.did_ftplugin_matlab_nvim then
    log("✓ did_ftplugin_matlab_nvim flag is set")
  else
    log("✗ did_ftplugin_matlab_nvim flag NOT set - ftplugin not loaded!")
  end
end

check_matlab_ftplugin()

-- Test 6: Check mappings with various methods
log("\n6. Mappings:")
local mappings = vim.api.nvim_get_keymap('n')
log("Total normal mode mappings: " .. #mappings)

-- Count potential MATLAB mappings
local matlab_count = 0
local space_m_count = 0

for _, map in ipairs(mappings) do
  -- Check for any Matlab-related commands or descriptions
  if (map.rhs and map.rhs:find("Matlab")) or 
     (map.desc and map.desc:find("[Mm]atlab")) then
    matlab_count = matlab_count + 1
    log("Found MATLAB mapping: '" .. map.lhs .. "' -> " .. 
        (map.rhs or "<function>") .. " (" .. (map.desc or "no description") .. ")")
  end
  
  -- Special check for space+m mappings
  if map.lhs and (map.lhs:find("^ m") or map.lhs == " m") then
    space_m_count = space_m_count + 1
    log("Found space+m mapping: '" .. map.lhs .. "' -> " .. 
        (map.rhs or "<function>") .. " (" .. (map.desc or "no description") .. ")")
  end
end

log("MATLAB-related mappings found: " .. matlab_count)
log("Space+m mappings found: " .. space_m_count)

-- Test 7: Create a minimal working mapping
log("\n7. Testing minimal space mapping:")
-- First show current leader
log("Leader key: '" .. (vim.g.mapleader or "\\") .. "'")

-- Try creating a space mapping explicitly
vim.keymap.set('n', ' m', '<cmd>echo "Space m works"<CR>', 
              {desc = "Test space m mapping"})
log("Created ' m' mapping")

-- Check if it was actually set
local found_test_mapping = false
for _, map in ipairs(vim.api.nvim_get_keymap('n')) do
  if map.lhs == " m" then
    found_test_mapping = true
    log("✓ Test mapping found")
    break
  end
end

if not found_test_mapping then
  log("✗ Test mapping NOT found - problem with space mappings!")
end

-- Test 8: Check commands
log("\n8. MATLAB commands:")
for _, cmd in ipairs({"MatlabRun", "MatlabBreakpoint", "MatlabKeymaps"}) do
  local exists = pcall(function()
    vim.api.nvim_command("silent! " .. cmd .. " --help")
  end)
  log(cmd .. ": " .. (exists and "✓ exists" or "✗ not found"))
end

-- Summary
log("\n===== Diagnostic Summary =====")
log("• MATLAB.nvim in runtimepath: " .. (found_matlab and "Yes" or "No"))
log("• Key modules loadable: " .. (modules_loadable and "Yes" or "No"))
log("• Filetype detection: " .. (vim.bo.filetype == "matlab" and "Working" or "Not working"))
log("• MATLAB mappings found: " .. matlab_count)
log("• Space+m mappings found: " .. space_m_count)
log("• Test mapping creation: " .. (found_test_mapping and "Working" or "Not working"))

log("\n===== End of Diagnostic =====")
