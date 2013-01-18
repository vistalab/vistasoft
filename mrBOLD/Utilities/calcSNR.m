function SNR = calcSNR(tc,cycles,inDB);
% calcSNR: calculate signal to noise ratio for a time course or set of time
% courses.
%
% Usage: SNR = calcSNR(tc,cycles,[inDB]);
%
% tc is time course data. It should be in the format time points x time
% courses, where the different rows are different time points and different
% columns are different time courses. A separate SNR is returned for each
% column.
%
% cycles can either be a single integer or a vector of length nTimePoints.
% If it's a single number, this is parsed as being the # of cycles, and the
% time course is assumed to vary sinusoidally b/w two conditions which are
% compared, with an equal cycle period. For any other time structure,
% cycles should specify the condition each time point belongs to. The SNR
% always considers condition 1 as signal and condition 2 as the noise; 
% other conditions are ignored. 
%
% inDB is a flag for whether to return a raw ratio (0) or a values in 
% decibels (1). It defaults to 1. Decibels are defined as 20 *
% log10(signal/noise). 
%
% 01/04 ras.
if ~exist('inDB','var')
    inDB = 1;
end

% if a single row vector is entered, make it a column vector
if size(tc,1)==1 & size(tc,2) > 1
    tc = tc';
end

if length(cycles)==1
    nCycles = cycles;
%     a = mod(0:2*nCycles-1,2) + 1;
%     cycles = a(round(linspace(1,2*nCycles,size(tc,1))));
    nFrames = size(tc,1);
    framesPerCycle = nFrames/nCycles;
    cycle = ones(1,framesPerCycle);
    cycle(framesPerCycle/2+1:end) = 2;
    cycles = repmat(cycle,[1 nCycles]);
elseif length(cycles) < size(tc,1)
    error('Either need to input # of cycles, or else specify which cycle each time point belongs to.');
end

SNR = [];
for i = 1:size(tc,2)
    subTC = tc(:,i);
    X = subTC(cycles==1);
    Y = subTC(cycles==2);
    SNR(i) = abs(nanmean(X) - nanmean(Y)) / std(Y);
end

% convert into dB if necessary (check this is the correct conversion)
if inDB
    SNR = 20 * log10(SNR);
end

return

