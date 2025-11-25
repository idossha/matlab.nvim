# Debug Testing Guide

This directory contains test files for matlab.nvim's debugging functionality.

## Test Files

### test_debug.m

Comprehensive test script that covers all debugging scenarios:
- Basic variable operations
- Arrays and matrices
- Loops (for, while)
- Conditionals (if/else)
- Function calls (simple, recursive, chained)
- Complex data types (cells, structs)
- Error handling (try/catch)

## How to Test

### Quick Test

1. **Open the test file:**
   ```
   nvim tests/test_debug.m
   ```

2. **Start MATLAB server:**
   ```
   :MatlabStartServer
   ```
   Or press `<Leader>mss` (default: Space + m + ss)

   **Note:** When you start debugging, the plugin will automatically `cd` MATLAB to the tests directory, so the file will be found correctly

3. **Set some breakpoints:**
   - Line 25: Basic variable operations (z = x + y)
   - Line 35: Matrix operations
   - Line 44: Inside for loop
   - Line 54: Conditional branch
   - Line 61: Before function call

4. **Start debugging:**
   ```
   :MatlabDebugStart
   ```
   Or press `<Leader>mds`

5. **Use debug commands:**
   - `<Leader>mdc` - Continue to next breakpoint
   - `<Leader>mdo` - Step over current line
   - `<Leader>mdi` - Step into function
   - `<Leader>mdt` - Step out of function
   - `<Leader>mdv` - Show variables (whos)
   - `<Leader>mdk` - Show call stack (dbstack)
   - `<Leader>mdx` - Evaluate expression

6. **Stop debugging when done:**
   ```
   :MatlabDebugStop
   ```
   Or press `<Leader>mde`

### Comprehensive Test Scenarios

#### Test 1: Basic Stepping
1. Set breakpoint on line 25 (z = x + y)
2. Start debug
3. Use `<Leader>mdv` to view variables
4. Press `<Leader>mdo` to step over
5. Check that z is now calculated

#### Test 2: Loop Iteration
1. Set breakpoint on line 44 (sum_val = sum_val + i)
2. Start debug
3. Press `<Leader>mdc` to continue to breakpoint
4. Press `<Leader>mdo` multiple times to watch loop iterations
5. Use `<Leader>mdv` to see i and sum_val change

#### Test 3: Function Stepping
1. Set breakpoint on line 61 (factorial_result = ...)
2. Start debug, continue to breakpoint
3. Press `<Leader>mdi` to step INTO compute_factorial function
4. Use `<Leader>mdk` to see call stack
5. Press `<Leader>mdt` to step OUT of function

#### Test 4: Recursive Functions
1. Set breakpoint inside compute_factorial (line 123)
2. Start debug on a factorial call
3. Step into the recursive calls
4. Use `<Leader>mdk` to see growing call stack
5. Watch the stack shrink as recursion unwinds

#### Test 5: Function Call Chain
1. Set breakpoints in function_chain_* functions
2. Call function_chain_start
3. Step through the entire chain: start → middle → end
4. Use call stack to see the chain

#### Test 6: Expression Evaluation
1. Stop at any breakpoint
2. Press `<Leader>mdx`
3. Enter expressions like:
   - `x + y`
   - `sum(A(:))`
   - `length(cell_data)`
   - `struct_data.name`

#### Test 7: Conditional Debugging
1. Set breakpoints in if/else branches (lines 52-56)
2. Change the value variable to test different paths
3. Verify correct branch is taken

## Debug Commands Reference

| Command | Mapping | Description |
|---------|---------|-------------|
| `:MatlabDebugStart` | `<Leader>mds` | Start debugging session |
| `:MatlabDebugStop` | `<Leader>mde` | Stop debugging session |
| `:MatlabDebugContinue` | `<Leader>mdc` | Continue to next breakpoint |
| `:MatlabDebugStepOver` | `<Leader>mdo` | Step over (execute line) |
| `:MatlabDebugStepInto` | `<Leader>mdi` | Step into function |
| `:MatlabDebugStepOut` | `<Leader>mdt` | Step out of function |
| `:MatlabDebugToggleBreakpoint` | `<Leader>mdb` | Toggle breakpoint |
| `:MatlabDebugClearBreakpoints` | `<Leader>mdd` | Clear all breakpoints |
| `:MatlabDebugShowVariables` | `<Leader>mdv` | Show variables (whos) |
| `:MatlabDebugShowStack` | `<Leader>mdk` | Show call stack (dbstack) |
| `:MatlabDebugShowBreakpoints` | `<Leader>mdp` | Show breakpoints (dbstatus) |
| `:MatlabDebugEval` | `<Leader>mdx` | Evaluate expression |

## What to Verify

When testing, verify that:

1. **Breakpoints work correctly:**
   - ✓ Red circle (●) appears in sign column
   - ✓ Execution stops at breakpoint
   - ✓ Can toggle breakpoints on/off
   - ✓ Can clear all breakpoints

2. **Stepping works:**
   - ✓ Step over executes current line
   - ✓ Step into enters function calls
   - ✓ Step out returns from function
   - ✓ Continue runs to next breakpoint

3. **Variable inspection:**
   - ✓ `whos` shows all variables
   - ✓ Can see variable values in MATLAB pane
   - ✓ Variables update as you step

4. **Call stack:**
   - ✓ `dbstack` shows current execution location
   - ✓ Stack grows with function calls
   - ✓ Stack shrinks when returning

5. **Breakpoint persistence:**
   - ✓ Breakpoints persist across debug sessions
   - ✓ Breakpoints restore when restarting debug
   - ✓ Signs stay visible

6. **Expression evaluation:**
   - ✓ Can evaluate simple expressions
   - ✓ Can inspect variable properties
   - ✓ Results show in MATLAB pane

## Troubleshooting Test Issues

**Breakpoint doesn't stop execution:**
- Ensure the line has executable code (not blank/comment)
- Check breakpoint is set: `:MatlabDebugShowBreakpoints`
- Verify file is saved

**Can't see variables:**
- Run `:MatlabDebugShowVariables`
- Check MATLAB pane for output
- Ensure you're in debug mode (paused at breakpoint)

**Step commands don't work:**
- Make sure debug session is active
- Check you're paused at a line (not just running)
- Try `:MatlabDebugStop` and restart

**MATLAB pane not showing output:**
- Verify MATLAB server is running
- Check tmux pane exists
- Try sending command manually in tmux pane

## Advanced Testing

### Test Breakpoint Sync
1. Set breakpoints in Neovim
2. In MATLAB pane, type `dbstatus` to verify
3. Add breakpoint directly in MATLAB: `dbstop in test_debug at 50`
4. Note: UI won't show this one (it's MATLAB-only)

### Test Multiple Files
1. Create another .m file that calls functions from test_debug.m
2. Set breakpoints in both files
3. Debug through cross-file function calls

### Test Error Conditions
1. Uncomment the `error()` call in test 11
2. Debug through try/catch
3. Verify execution goes to catch block

## Manual MATLAB Commands

You can also type debug commands directly in the MATLAB tmux pane:

```matlab
dbstop in test_debug at 25    % Set breakpoint
dbstatus                       % Show all breakpoints
dbcont                         % Continue
dbstep                         % Step over
dbstep in                      % Step into
dbstep out                     % Step out
dbstack                        % Show call stack
whos                           % Show variables
dbquit                         % Quit debug mode
dbclear all                    % Clear all breakpoints
```

## Success Criteria

A successful test run should demonstrate:
- ✓ All 12 test sections execute correctly
- ✓ Breakpoints can be set/cleared/toggled
- ✓ Step over/into/out work as expected
- ✓ Variables are visible and update correctly
- ✓ Call stack shows correct function hierarchy
- ✓ Expression evaluation works
- ✓ No errors or crashes
- ✓ Debug session can be stopped cleanly
