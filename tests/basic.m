% This is a basic MATLAB script

%% This is a MATLAB cell

% This is a comment

% This is another comment

% This is a comment

% This is a comment
a = 1;
b = 2;
c = a + b;

%% This is another MATLAB cell

% This is a comment

% This is another comment

% This is a comment
d = 3;
e = 4;
f = d + e;

%% basic plit test

x = linspace(0, 2*pi, 100);
y = sin(x);
plot(x,y, 'b-', 'LineWidth', 2);
xlabel('x');
ylabel('y');
title('sin(x)');
grid on;
