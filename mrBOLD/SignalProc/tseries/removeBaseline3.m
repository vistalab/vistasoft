function tSeries = removeBaseline3(tSeries, period, numIterations)

% function tSeries = removeBaseline3(tSeries, period, numIterations);
%
% Use multiple boxcar smoothing operations (number given by
% numIterations, default is 2) to remove low-frequency baseline
% drift from the input time series (tSeries) using the input
% period. The input is assumed to be two-dimensional, with time
% as the low-order dimension.
%
% DBR  5/00

% Create boxcar kernel:
kernel = ones([period 1]) / period;

if ~exist('numIterations')
    numIterations = 2;
end

bLine = tSeries;
for i=1:numIterations
    bLine = upConv(bLine,kernel,'repeat');
end
% Remove baseline from time series:
tSeries = tSeries - bLine;


