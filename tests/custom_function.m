%% Initialize workspace
% This cell sets up our initial variables
clear all;
close all;
clc;

% Create some sample data
x = linspace(0, 2*pi, 100);
y = sin(x);
z = cos(x);

disp('Workspace initialized with sample data (x, y, z)');

%% Plotting demonstration
% This cell creates a visualization
figure;
plot(x, y, 'b-', 'LineWidth', 2);
hold on;
plot(x, z, 'r--', 'LineWidth', 2);
grid on;
xlabel('x');
ylabel('Amplitude');
title('Sine and Cosine Functions');
legend('sin(x)', 'cos(x)');

% Create a custom data structure
data.x = x;
data.y = y;
data.z = z;
data.description = 'Sample trigonometric data';

disp('Plot created and data structure initialized');
