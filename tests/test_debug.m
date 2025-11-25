%% MATLAB Debug Test Script
% This script tests various debugging scenarios for matlab.nvim
%
% How to use:
% 1. Open this file in Neovim
% 2. Set breakpoints on lines you want to test (e.g., lines 25, 35, 45)
% 3. Run :MatlabDebugStart
% 4. Use debug commands to step through
%
% Test scenarios:
% - Simple variable assignments
% - Function calls
% - Loops
% - Conditionals
% - Nested function calls
% - Error conditions

%% Test 1: Basic Variable Operations
fprintf('Test 1: Basic Variables\n');
x = 10;
y = 20;
z = x + y;  % Set breakpoint here - should show x=10, y=20
fprintf('x=%d, y=%d, z=%d\n', x, y, z);

%% Test 2: Arrays and Matrices
fprintf('\nTest 2: Arrays and Matrices\n');
A = [1 2 3; 4 5 6; 7 8 9];
B = magic(3);
C = A + B;  % Set breakpoint here - inspect A, B matrices
fprintf('Matrix A size: %dx%d\n', size(A));
fprintf('Matrix sum:\n');
disp(C);

%% Test 3: Loop Testing
fprintf('\nTest 3: For Loop\n');
sum_val = 0;
for i = 1:5
    sum_val = sum_val + i;  % Set breakpoint here - watch sum_val grow
    fprintf('  i=%d, sum=%d\n', i, sum_val);
end
fprintf('Final sum: %d\n', sum_val);

%% Test 4: Conditional Logic
fprintf('\nTest 4: Conditionals\n');
value = 42;
if value > 50
    result = 'large';  % Should not execute
elseif value > 30
    result = 'medium';  % Set breakpoint here - should hit this branch
else
    result = 'small';
end
fprintf('Value %d is %s\n', value, result);

%% Test 5: Function Calls
fprintf('\nTest 5: Function Calls\n');
input_val = 7;
factorial_result = compute_factorial(input_val);  % Set breakpoint - test dbstep into
fprintf('%d! = %d\n', input_val, factorial_result);

%% Test 6: Nested Loops
fprintf('\nTest 6: Nested Loops\n');
for i = 1:3
    for j = 1:3
        product = i * j;  % Set breakpoint here - watch i, j change
        fprintf('  %d x %d = %d\n', i, j, product);
    end
end

%% Test 7: String Operations
fprintf('\nTest 7: Strings\n');
str1 = 'Hello';
str2 = 'World';
combined = [str1 ' ' str2];  % Set breakpoint - inspect strings
fprintf('Combined: %s\n', combined);

%% Test 8: Cell Arrays and Structures
fprintf('\nTest 8: Complex Data Types\n');
cell_data = {'apple', 'banana', 'cherry'};
struct_data.name = 'Test';
struct_data.value = 123;
struct_data.active = true;  % Set breakpoint - inspect cell and struct
fprintf('First fruit: %s\n', cell_data{1});
fprintf('Struct name: %s\n', struct_data.name);

%% Test 9: Function with Multiple Returns
fprintf('\nTest 9: Multiple Return Values\n');
[mean_val, std_val] = compute_stats([1 2 3 4 5]);
fprintf('Mean: %.2f, Std: %.2f\n', mean_val, std_val);

%% Test 10: While Loop
fprintf('\nTest 10: While Loop\n');
counter = 0;
while counter < 5
    counter = counter + 1;  % Set breakpoint - watch counter increment
    fprintf('  Counter: %d\n', counter);
end

%% Test 11: Try-Catch Error Handling
fprintf('\nTest 11: Error Handling\n');
try
    risky_value = 10 / 2;  % Set breakpoint - normal execution
    fprintf('  Division succeeded: %.2f\n', risky_value);
    % Uncomment to test error path:
    % error('Simulated error');
catch err
    fprintf('  Caught error: %s\n', err.message);
end

%% Test 12: Advanced Function Call Chain
fprintf('\nTest 12: Function Call Chain\n');
initial = 5;
final = function_chain_start(initial);  % Test dbstep into through chain
fprintf('Chain result: %d -> %d\n', initial, final);

fprintf('\n=== All tests complete ===\n');

%% Helper Functions

function result = compute_factorial(n)
    % Computes factorial recursively
    % Set breakpoint here to test stepping into functions
    if n <= 1
        result = 1;
    else
        result = n * compute_factorial(n - 1);  % Test recursive debugging
    end
end

function [mean_val, std_val] = compute_stats(data)
    % Computes mean and standard deviation
    % Set breakpoint to inspect input data
    mean_val = mean(data);
    std_val = std(data);
end

function result = function_chain_start(x)
    % First function in a chain
    result = function_chain_middle(x * 2);  % Test dbstep into
end

function result = function_chain_middle(x)
    % Middle function in a chain
    result = function_chain_end(x + 10);  % Test dbstep into
end

function result = function_chain_end(x)
    % Final function in a chain
    result = x * 3;  % Set breakpoint here
end
