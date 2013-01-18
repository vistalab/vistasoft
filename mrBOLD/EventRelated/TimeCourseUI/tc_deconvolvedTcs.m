function tc = tc_deconvolvedTcs(view,tc);
% tc = tc_deconvolvedTcs(view,tc);
%
% For Time Course UI, process a 
% rapid event-related time course
% for plotting.
%
% The convention for storing deconvolved
% time courses (borrowed from FS-FAST's
% convention) is to have alternating
% mean time courses for each voxel and
% variance estimates. Putting this
% format time course directly into
% er_chopTSeries produces problems. This 
% code arranges things so that the tc
% struct is set up nicely.
%
% 09/04 ras.

prestim = round(sum(tc.params.timeWindow<0) / tc.TR);
scans = tc.params.scans;

% figure out the size of the deconvolved time
% window from the spacing between onsets (each 
% onset is a different condition):
twSize = (tc.trials.onsetSecs(2) - tc.trials.onsetSecs(1)) / 2;
nConds = sum(tc.trials.condNums>0);
if isfield(tc,'wholeTc') % TCUI
    condData = reshape(tc.wholeTc, [2*twSize nConds]);
else                     % MVUI
    condData = reshape(tc.tSeries, [2*twSize nConds]);
end

tc.meanTcs = condData(1:twSize,:);
% maxT = find(mean(tc.meanTcs,2)==max(mean(tc.meanTcs,2)));
% tc.timeWindow = tc.TR .* [(0:twSize-1)-prestim];
% tc.peakPeriod = tc.timeWindow(maxT-1:maxT+1);
% tc.bslPeriod = tc.timeWindow(1:prestim+1);

%%%%% convert params expressed in secs into frames
frameWindow = unique(round(tc.params.timeWindow./tc.TR));
prestim = -1 * frameWindow(1);
peakFrames = unique(round(tc.params.peakPeriod./tc.TR));
bslFrames = unique(round(tc.params.bslPeriod./tc.TR));
peakFrames = find(ismember(frameWindow,peakFrames));
bslFrames = find(ismember(frameWindow,bslFrames));


% normalize the 'betas' part of the condition data
% such that the baseline period is zero, then
% recompute the mean Tcs:
bsl = tc.meanTcs(bslFrames,:);
bsl = nanmean(bsl(:));
tc.meanTcs = tc.meanTcs - bsl;
tc.allTcs = permute(tc.meanTcs,[1 3 2]);

% also seems to be a gratuitious multiplication
% by 100 here, (sometimes), during the percent signal 
% change step -- compensate:
if any(tc.meanTcs>20)
	tc.meanTcs = tc.meanTcs ./ 100;
	tc.allTcs = tc.allTcs ./ 100;
end

% add zeros for baseline condition
tc.meanTcs = [zeros(twSize,1) tc.meanTcs];
tc.stds = sqrt(condData(twSize+1:end,:)); 
tc.stds = [zeros(twSize,1) tc.stds];

% % sometimes the stds are screwed up too...?
% tc.stds = tc.stds .* 100;


% if an h.dat file exists, containing the # of
% observations per condition, get this information
% and use it to convert our time course stds -> true
% sems:
hdatPath = fullfile(tSeriesDir(view),['Scan' num2str(scans(1))],'h.dat');
if exist(hdatPath,'file')
    hdr = er_readHdat(hdatPath);
    dof = hdr.trialsPerCond-1;
    tc.sems = tc.stds ./ repmat(dof,[twSize 1]);
end

%%%%% norm baseline periods
for c = 1:nConds
    offset = mean(tc.meanTcs(bslFrames,c));
    tc.meanTcs(bslFrames,c) = tc.meanTcs(bslFrames,c) - offset;
end

%%%%% calc amplitudes, do t-tests of post-baseline v. baseline
Hs = NaN*ones(1,nConds);

for i = 1:nConds
    bsl = tc.allTcs(bslFrames,:,i);
    peak = tc.allTcs(peakFrames,:,i);
    try
        [tc.Hs(i) tc.ps(i)] = ttest2(bsl(:),peak(:),tc.params.alpha,-1);
    catch
        tc.Hs(i) = 0; tc.ps(i) = 1;
    end
    tc.amps(:,i+1) = (nanmean(peak) - nanmean(bsl))';
end

%%%%% compute Signal-to-Noise Ratio
allBsl = tc.meanTcs(bslFrames,:,:);
allPk = tc.meanTcs(peakFrames,:,:);
SNR = abs(mean(allPk(:)) - mean(allBsl(:))) / std(allBsl(:));

%%%%% compute relamps 
relamps = fmri_relamps(permute(tc.allTcs,[1 3 2]));

%%%%% note the deconvolved tc setting
tc.params.deconvolved = 1;

return