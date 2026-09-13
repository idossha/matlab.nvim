-- Public setup/command/mapping contract, exercised in real Neovim buffers.
return function(test)
  local plugin = require('matlab')
  local tmux = require('matlab.tmux')
  test('setup registers commands and routes MATLAB test execution', function()
    local exists, run = tmux.exists, tmux.run
    local sent = {}
    tmux.exists = function() return true end
    tmux.run = function(command) sent[#sent + 1] = command end
    local ok, err = xpcall(function()
      plugin.setup({ auto_start = false })
      local commands = vim.api.nvim_get_commands({ builtin = false })
      for _, name in ipairs({ 'MatlabRun', 'MatlabRunTests', 'MatlabDebugStart', 'MatlabDebugContinue', 'MatlabRunCell' }) do
        assert(commands[name], name .. ' missing')
      end
      vim.cmd('MatlabRunTests')
      assert(vim.deep_equal(sent, { 'runtests(pwd)' }))
      plugin.setup({ auto_start = false })
      assert(#vim.api.nvim_get_autocmds({ group = 'matlab_nvim', event = 'FileType' }) == 1)
    end, debug.traceback)
    tmux.exists, tmux.run = exists, run
    vim.api.nvim_del_augroup_by_name('matlab_nvim')
    vim.api.nvim_del_augroup_by_name('MatlabDebug')
    assert(ok, err)
  end)
  test('custom mappings stay buffer-local and preserve default debug mappings', function()
    local previous = vim.api.nvim_get_current_buf()
    local buffer = vim.api.nvim_create_buf(false, true)
    local ok, err = xpcall(function()
      vim.api.nvim_set_current_buf(buffer)
      plugin.config.setup({ mappings = { prefix = ',m', run = 'R' } })
      dofile('ftplugin/matlab.lua')
      local maps = {}
      for _, map in ipairs(vim.api.nvim_buf_get_keymap(buffer, 'n')) do maps[map.lhs] = map.rhs end
      assert(maps[',mR'] == '<Cmd>MatlabRun<CR>')
      assert(maps[',mdc'] == '<Cmd>MatlabDebugContinue<CR>')
      assert(maps[',mT'] == '<Cmd>MatlabRunTests<CR>')
      for _, map in ipairs(vim.api.nvim_get_keymap('n')) do assert(map.lhs ~= ',mR') end
    end, debug.traceback)
    vim.api.nvim_set_current_buf(previous)
    vim.api.nvim_buf_delete(buffer, { force = true })
    plugin.config.setup({})
    assert(ok, err)
  end)
  test('mapping opt-out creates no plugin buffer mappings', function()
    local previous = vim.api.nvim_get_current_buf()
    local buffer = vim.api.nvim_create_buf(false, true)
    local ok, err = xpcall(function()
      vim.api.nvim_set_current_buf(buffer)
      plugin.config.setup({ default_mappings = false })
      dofile('ftplugin/matlab.lua')
      assert(#vim.api.nvim_buf_get_keymap(buffer, 'n') == 0)
    end, debug.traceback)
    vim.api.nvim_set_current_buf(previous)
    vim.api.nvim_buf_delete(buffer, { force = true })
    plugin.config.setup({})
    assert(ok, err)
  end)
end
