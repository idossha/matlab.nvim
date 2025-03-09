%% Introduction and Setup
% This is a test file to demonstrate MATLAB.nvim plugin features
% It contains multiple cells, variables, and functions

% Clear workspace and close figures
clear all;
close all;
clc;

% Set default figure properties
set(0, 'DefaultFigureWindowStyle', 'docked');

%% Basic Variable Definitions
% Test different variable types to see in workspace viewer

% Numeric variables
scalar = 42;
vector = [1, 2, 3, 4, 5];
matrix = [1, 2, 3; 4, 5, 6; 7, 8, 9];
complex_num = 3 + 4i;

% String and character variables
str = "This is a string";
char_array = 'This is a character array';

% Logical variables
logical_var = true;
logical_array = [true, false, true, false];

% Cell array
cell_data = {1, 'text', [1,2,3], struct('name', 'value')};

% Structure
person = struct('name', 'John', 'age', 30, 'city', 'New York');

% Table
T = table([1; 2; 3], ['A'; 'B'; 'C'], [true; false; true], ...
    'VariableNames', {'Numbers', 'Letters', 'Logical'});

%% Mathematical Operations
% Demonstrate basic math operations

% Element-wise operations
a = [1, 2, 3, 4];
b = [5, 6, 7, 8];

sum_ab = a + b;
diff_ab = a - b;
prod_ab = a .* b;
div_ab = a ./ b;
pow_ab = a .^ 2;

% Matrix operations
A = reshape(1:9, [3, 3]);
B = eye(3);

mat_sum = A + B;
mat_prod = A * B;
transpose_A = A';
det_A = det(A);
inv_A = inv(A);

%% Statistical Analysis
% Generate and analyze random data

% Generate random data
rand_data = randn(1000, 1);

% Calculate statistics
mean_val = mean(rand_data);
median_val = median(rand_data);
std_val = std(rand_data);
min_val = min(rand_data);
max_val = max(rand_data);

% Histogram plot
figure;
histogram(rand_data, 30);
title('Histogram of Random Data');
xlabel('Value');
ylabel('Frequency');

%% Signal Processing Example
% Create and process a simple signal

% Time vector
fs = 1000;  % Sampling frequency (Hz)
t = 0:1/fs:1-1/fs;  % Time vector of 1 second

% Create a signal with multiple frequency components
f1 = 50;  % 50 Hz
f2 = 120; % 120 Hz
signal = sin(2*pi*f1*t) + 0.5*sin(2*pi*f2*t) + 0.2*randn(size(t));

% Plot the signal
figure;
plot(t(1:500), signal(1:500));
title('Time Domain Signal');
xlabel('Time (s)');
ylabel('Amplitude');

% Compute and plot the spectrum
N = length(signal);
frequencies = (0:N-1)*(fs/N);
spectrum = abs(fft(signal))/N;

figure;
plot(frequencies(1:N/2), spectrum(1:N/2)*2);
title('Frequency Spectrum');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
xlim([0, 200]);

%% Image Processing
% Create and manipulate a simple image

% Create a sample image
img_size = 100;
[X, Y] = meshgrid(linspace(-2, 2, img_size), linspace(-2, 2, img_size));
R = sqrt(X.^2 + Y.^2);
Z = sin(R)./R;
Z(isnan(Z)) = 1;  % Fix division by zero

% Display the image
figure;
imagesc(Z);
colormap(jet);
colorbar;
title('Sample Image');
axis equal tight;

% Apply a filter
filtered_img = imgaussfilt(Z, 2);

% Display the filtered image
figure;
imagesc(filtered_img);
colormap(jet);
colorbar;
title('Filtered Image');
axis equal tight;

% Calculate the difference
diff_img = Z - filtered_img;

% Display the difference
figure;
imagesc(diff_img);
colormap(jet);
colorbar;
title('Difference');
axis equal tight;

%% Custom Function Definition
% Define a function inside the script

function output = custom_function(input, factor)
    % A simple function that multiplies input by factor
    % and adds a random number
    
    if nargin < 2
        factor = 1;
    end
    
    output = input * factor + rand();
    
    % Print output for demonstration
    fprintf('Input: %f, Factor: %f, Output: %f\n', input, factor, output);
end

%% Function Calls
% Test the custom function

result1 = custom_function(5);
result2 = custom_function(10, 2);
result3 = custom_function(15, 0.5);

results = [result1, result2, result3];
disp('Results from function calls:');
disp(results);

%% Script End
% Summary of what we've covered

disp('Test file completed!');
disp('This file demonstrated:');
disp('- Different variable types');
disp('- Mathematical operations');
disp('- Statistical analysis');
disp('- Signal processing');
disp('- Image processing');
disp('- Custom functions');

% End time
end_time = now;
disp(['Finished at: ', datestr(end_time)]);
