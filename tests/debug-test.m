% Debug Test Script for matlab.nvim
% This script demonstrates debugging functionality

% Initialize variables
a = 1;
b = 2;

% Simple calculation - set breakpoint here
c = a + b;

% Function call - step into this
result = multiply_by_two(c);

% Display result
fprintf('Result: %d\n', result);

% Nested function for testing step into/out
function y = multiply_by_two(x)
    % Set breakpoint here to test stepping
    y = x * 2;

    % Another operation
    y = y + 1;
end
