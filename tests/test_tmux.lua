-- Exercise pane identity and emitted transport arguments at the tmux boundary.
return function(test)
  local tmux = require('matlab.tmux')
  local function with_transport(fn)
    local execute, pane = tmux.execute, tmux.server_pane
    local sent = {}
    tmux.server_pane = '$0:@1.%4'
    tmux.execute = function(cmd)
      if cmd:find('list-panes', 1, true) then return '%4\n%41\n' end
      sent[#sent + 1] = cmd
      return ''
    end
    local ok, err = xpcall(function() fn(sent) end, debug.traceback)
    tmux.execute, tmux.server_pane = execute, pane
    assert(ok, err)
  end
  test('pane identity matches an exact pane in the list', function()
    with_transport(function()
      assert(tmux.pane_exists())
      tmux.server_pane = '%41'
      assert(tmux.pane_exists())
      tmux.server_pane = '%1'
      assert(not tmux.pane_exists())
    end)
  end)
  test('missing pane is not confused with a longer pane ID', function()
    with_transport(function()
      tmux.execute = function() return '%41\n' end
      assert(not tmux.pane_exists())
    end)
  end)
  test('MATLAB command text survives shell transport unchanged', function()
    with_transport(function(sent)
      local code = [[disp("a'b $HOME $(echo unsafe)");]]
      tmux.run(code, true)
      assert(#sent == 2, vim.inspect(sent))
      -- Replace only the tmux command with printf; let the real shell decode args.
      local args = vim.fn.systemlist([[printf '%s\n' ]] .. sent[1]:sub(#'send-keys ' + 1))
      assert(vim.v.shell_error == 0)
      assert(args[1] == '-l', 'tmux must send literal text, not key names')
      assert(args[#args] == code, vim.inspect(args))
      assert(sent[2]:find('Enter', 1, true))
    end)
  end)
  test('debug continuation skips interrupt while ordinary commands interrupt', function()
    with_transport(function(sent)
      tmux.run('dbcont', true)
      assert(#sent == 2)
      tmux.run('x = 1')
      assert(#sent == 5)
      assert(sent[3]:find('C-c', 1, true))
    end)
  end)
end
