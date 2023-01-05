function tSeries = removeBaseline(tSeries, period, numIterations)

% function tSeries = removeBaseline(tSeries, period, numIterations);
%
% Use multiple boxcar smoothing operations (number given by
% numIterations, default is 2) to remove low-frequency baseline
% drift from the input time series (tSeries) using the input
% period.
%

% Create boxcar kernel:
kernel = ones([period 1]) / period;

if ~exist('numIterations')
  numIterations = 2;
end

% Initialize the baseline array to the time with 1-period
% padding at beginning and end:
ntPoints = length(tSeries);
mValue = mean(tSeries(:));
bLine = zeros(ntPoints + 2*period, 1);
bLine(1:period) = mean(tSeries(1:period));
bLine(period+1:period+ntPoints) = tSeries;
bLine(period+ntPoints+1:end) = mean(tSeries(ntPoints-period+1:ntPoints));

% Define indices for post-smoothing array "trim":
addPts = numIterations * (period - 1);
start = floor(addPts/2) + 1;
stop = length(bLine) + floor(addPts/2);

% Smoothing loop -- convolve with boxcar, then "trim" array:
for i=1:numIterations, bLine = conv(bLine, kernel); end
bLine = bLine(start:stop);

% Remove baseline from time series:
tSeries = tSeries - bLine(period+1:period+ntPoints);

return;
