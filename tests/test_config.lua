-- Authored configuration behavior; no MATLAB or external tools required.
return function(test)
  local config = require('matlab.config')
  test('configuration preserves unspecified nested defaults', function()
    config.setup({ auto_start = false, mappings = { run = 'R' } })
    assert(config.get('auto_start') == false)
    assert(config.get('mappings').run == 'R')
    assert(config.get('mappings').debug_continue == 'c')
    config.setup({})
    assert(config.get('auto_start') == true)
    assert(config.get('mappings').run == 'r')
  end)
  test('configuration does not mutate caller options or defaults', function()
    local opts = { debug_ui = { sidebar_width = 60 } }
    config.setup(opts)
    config.options.debug_ui.sidebar_width = 80
    assert(opts.debug_ui.sidebar_width == 60)
    assert(config.defaults.debug_ui.sidebar_width == 40)
    config.setup({})
  end)
end
