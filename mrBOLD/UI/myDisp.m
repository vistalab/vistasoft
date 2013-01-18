function myDisp(msg)
%
% myDisp(msg)
%
% Calls Matlab's disp with current time. Used to measure performance.
%
% MA, 10/27/2004

t = clock;
h = t(4);
m = t(5); 
s = t(6);
disp([msg, ' ', int2str(h), ':', int2str(m), ':', num2str(s)]);
return;