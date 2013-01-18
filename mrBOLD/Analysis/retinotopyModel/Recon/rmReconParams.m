function p=rmReconParams(vw)

% this parameters is needed to load all raw-data
p.wData = 'all';

% convert data to percent BOLD
p.analysis.calcPC  = true;

% number of trends
p.analysis.nDCT = 4;

% stimulus parameters
ns = viewGet(vw,'nscans');
for n=1:ns
    p.stim(n).nFrames    = viewGet(vw,'numframes',n);
    p.stim(n).nUniqueRep = 1;
    p.stim(n).nDCT = p.analysis.nDCT;
end

% thresholds above which to use voxels
p.thresh.rmVarexp = 0.15; % goodness of fit of pRF model
p.thresh.stimTmap = 1.96; % goodness of fit of stimuli

% Number of events in a par file
p.numOfEvents = 37;