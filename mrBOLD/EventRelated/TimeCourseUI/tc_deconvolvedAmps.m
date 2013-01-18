function tc = tc_deconvolvedAmps(tc);
% tc = tc_deconvolvedAmps(tc);
% compute the peak-bsl amplitudes of deconvolved
% time courses (and relamps, when I implement that):

%%%%%% get params
frameWindow = unique(round(tc.params.timeWindow./tc.TR));
prestim = -1 * frameWindow(1);
peakFrames = unique(round(tc.params.peakPeriod./tc.TR));
bslFrames = unique(round(tc.params.bslPeriod./tc.TR));
peakFrames = find(ismember(frameWindow,peakFrames));
bslFrames = find(ismember(frameWindow,bslFrames));


%%%%% norm baseline periods
nConds = size(tc.glm.betas, 2);

if tc.params.normBsl==1
    offset = mean(tc.glm.betas(bslFrames,:), 1);
    tc.glm.betas = tc.glm.betas - repmat(offset, [length(frameWindow) 1]);
end

%%%%% calc amplitudes
for i = 1:nConds
    bsl = tc.glm.betas(bslFrames, i);
    peak = tc.glm.betas(peakFrames, i);
    tc.glm.amps(:,i) = (nanmean(peak) - nanmean(bsl))';
    tc.glm.amp_sems(:,i) = nanmean(tc.glm.sems(:,i))';
end    

return