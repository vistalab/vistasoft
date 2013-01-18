function sy = dtiSmoothCurve(y,cutoffFreq)
% 
% 
% 
% 
% 

if ieNotDefined('cutoffFreq'), cutoffFreq = 0.75; end

% design a butterworth 5th order lowpass filter
[b,a] = butter(5,cutoffFreq,'low');

% apply the filter
sy = filtfilt(b,a,y);

return
