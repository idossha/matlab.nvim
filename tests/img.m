

s = 1000;
t = 0:1/s:1;

f = 5;
y = sin(2*pi*f*t);

plot(t,y);

xlabel('Time (s)');
ylabel('Amplitude');
title('Sine Wave');

grid on;
