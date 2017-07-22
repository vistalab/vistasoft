function relamps = er_relamps(trialData);
%
% relamps = er_relamps(trialData);
%
% calculates the relative fMRI amplitude for multiple fMRI time courses,
% using the method given in Ress & Heeger, NN2002. (Dot-product w/ avg TC).
%
% trialData: matrix in which rows represent different points relative
% to a stimulus onset (see er_chopTSeries, the allTcs or meanTcs 
% fields of the output struct).
%
% relamps: a matrix with one fMRI relative amplitude for each column.
% The size of relamps is going to be the size of trialData, with 
% the rows dimension squeezed out. E.g. if trialData had size 
% time points x conditions x trials x subjects, relamps would have 
% size conditions x trials x subjects.
%
% The procedure to compute a fMRI relative amplitude is as follows:
%   (1) normalize each trial to have a mean of 0
%   (2) compute mean time course across all trials
%   (3) take dot (scalar) product of each column's time course
%       with the average time course, divided by the dot 
%       product of the average time course with itself. This
%       normalizes the relative amplitude to have the same
%       units as the input data (generally % signal change).
%
%
% ras 05/05. Improved on old, nonworking fmri_relamps code.

% reshape to be a 2D matrix w/ many columns, if necessary
sz = size(trialData);
if ndims(trialData)>2
    reshapeFlag = 1;
	trialData = reshape(trialData,[sz(1) prod(sz(2:end))]);
else 
    reshapeFlag = 0;
end
nTrials = size(trialData,2);

% normalize each column to have mean 0
offset = nanmean(trialData);
offset = repmat(offset,[sz(1) 1]);
trialData = trialData - offset;

% compute avg time course across all conditions/trials/etc
avgTC = nanmeanDims(trialData,2);

% take dot product of each trial's time course w/ avg
relamps = NaN*ones(1,nTrials);
% if nTrials > 100
%     hwait = mrvWaitbar(0,'Computing dot-product relative amplitudes')
% end
for i = 1:nTrials
    relamps(i) = dot(avgTC,trialData(:,i)) ./ dot(avgTC,avgTC);

%     if nTrials > 100
%         mrvWaitbar(i/nTrials,hwait);
% 	end
end
% if nTrials > 100
%     close(hwait)
% end


% reshape back to appropriate size, if necessary
if reshapeFlag==1    
    newSz = sz(2:end);
    relamps = reshape(relamps,newSz);
end

return