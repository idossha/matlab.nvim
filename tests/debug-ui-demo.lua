-- MATLAB Debug UI Demo Script
-- This script demonstrates how to use the new debug UI windows

print("=== MATLAB Debug UI Demo ===")
print()

print("1. Basic Debug UI Commands:")
print("   :MatlabDebugUI                    - Show all debug windows")
print("   :MatlabDebugCloseUI               - Close all debug windows")
print()

print("2. Individual Window Commands:")
print("   :MatlabDebugShowVariables         - Show variables window")
print("   :MatlabDebugShowCallstack         - Show call stack window")
print("   :MatlabDebugShowBreakpoints       - Show breakpoints window")
print("   :MatlabDebugShowRepl              - Show REPL window")
print()

print("3. Toggle Commands:")
print("   :MatlabDebugToggleVariables       - Toggle variables window")
print("   :MatlabDebugToggleCallstack       - Toggle call stack window")
print("   :MatlabDebugToggleBreakpoints     - Toggle breakpoints window")
print("   :MatlabDebugToggleRepl            - Toggle REPL window")
print()

print("4. Key Mappings (with <Leader>md prefix):")
print("   <Leader>mdu                       - Show all debug UI")
print("   <Leader>mdv                       - Show variables")
print("   <Leader>mdk                       - Show call stack")
print("   <Leader>mdp                       - Show breakpoints")
print("   <Leader>mdr                       - Show REPL")
print("   <Leader>mtv                       - Toggle variables")
print("   <Leader>mtk                       - Toggle call stack")
print("   <Leader>mtp                       - Toggle breakpoints")
print("   <Leader>mtr                       - Toggle REPL")
print("   <Leader>mdx                       - Close all UI")
print()

print("5. Window Controls:")
print("   Press 'q', <Esc>, or <C-c> in any window to close it")
print("   Use 'i' in REPL window to enter insert mode")
print("   Press <CR> in REPL to execute MATLAB commands")
print()

print("6. Configuration:")
print("   You can customize window positions and sizes in your config:")
print([[
   require('matlab').setup({
     debug_ui = {
       variables_position = 'right',
       variables_size = 0.3,
       callstack_position = 'bottom',
       callstack_size = 0.3,
       -- ... etc
     }
   })
]])
print()

print("7. Demo Workflow:")
print("   1. Open a MATLAB file in Neovim (in tmux)")
print("   2. Start MATLAB: :MatlabStartServer")
print("   3. Set some breakpoints: <Leader>mdb")
print("   4. Start debugging: <Leader>mds")
print("   5. Open debug UI: <Leader>mdu")
print("   6. Step through code and watch the windows update")
print("   7. Use REPL to execute MATLAB commands")
print("   8. Close UI when done: <Leader>mdx")
print()

print("=== End Demo ===")
