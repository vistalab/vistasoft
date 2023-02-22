function anal = er_chopTSerieskgs(view,coords,scans,varargin);

% anal = er_chopTSerieskgs(view,[roi],[scans],varargin);
%
% Concatenates tSeries from the selected scans together,
% chops up according to the assigned parfiles, and returns
% an analysis struct with the following fields:
%
%   allTcs:
%   meanTcs:
%   sems:
%   amps:
%   relamps:
%   hMat:
%   pMat:
%   SNR
%
% 06/17/04 ras: wrote it.
% 06/25/04 kgs
global dataTYPES;

if ieNotDefined('coords')
    rois = viewGet(view,'rois');
    selRoi = viewGet(view,'selectedroi');
    coords = rois(selRoi).coords;
end

dt = viewGet(view,'curdt');

if ieNotDefined('scans')
    [scans dt] = er_getScanGroup(view);
    view = viewSet(view,'curdt',dt);
end

%%%%% params/defaults %%%%%
normBsl = 1;            % flag to zero baseline or not
alpha = 0.05;           % threshold for significant activations
TR = dataTYPES(dt).scanParams(scans(1)).framePeriod;
bslPeriod = [-4:0 ];  % period to use as baseline in t-tests, in seconds
peakPeriod = 6:12; % 6:12      % period to look for peaks in t-tests, in seconds
timeWindow = -4:20;            % seconds relative to trial onset to take for each trial
onsetDelta = -4;               % # secs to shift onsets in parfiles, relative to time course
prestim=-4;                    % secs before stim onset for which the window is calculated

%%%%% parse the options %%%%%
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch lower(varargin{i})
        case 'normbsl', normBsl = varargin{i+1};
        case 'alpha', alpha = varargin{i+1};
        case 'peakperiod', peakPeriod = varargin{i+1};
        case 'timewindow', timeWindow = varargin{i+1};
        case 'scans', scans = varargin{i+1};
        case 'dt', dt = varargin{i+1};
        case 'onsetdelta', onsetDelta = varargin{i+1};
        case 'snrcond',snrcond=varagin{i+1}
        otherwise, % ignore
        end
    end
end

%%%%% concatenate tSeries from selected scans
allt = [];
fprintf('Loading tSeries from selected scans ... \t');
for s = scans
 subt = meanTSeries(view,s,coords);
  
   allt = [allt subt'];
   fprintf('%i ',s);
end
fprintf('\n');

%%%%% get parfile info, if it's not passed in in varargin
trials = er_concatParfiles(view,scans);
trials.onsetSecs = trials.onsetSecs + onsetDelta;
trials.onsetFrames = trials.onsetFrames + onsetDelta/TR;

%%%%% get nConds from trials struct
nConds = max(trials.cond);
nTrials = length(scans); % current operating assumption

%%%%% get a set of label names, if they were specified in the parfiles
for i = 1:nConds
    ind = find(trials.cond==i);
    labels{i} = trials.label{ind(1)};
end

%%%%% convert params expressed in secs into frames
frameWindow = unique(round(timeWindow./TR));
prestim = -1 * frameWindow(1);
peakFrames = unique(round(peakPeriod./TR));
bslFrames = unique(round(bslPeriod./TR));
peakFrames = find(ismember(frameWindow,peakFrames))
bslFrames = find(ismember(frameWindow,bslFrames));

%%%%% build tc matrix of trials x time points x conditions
%%%%% take (frameWindow) secs from each trial
tc = zeros(length(scans),length(frameWindow),nConds);

for i = 1:nConds
   ind = find(trials.cond==i);
   for j = 1:length(scans)
       tstart = trials.onsetFrames(ind(j));
       tend = min([tstart+frameWindow(end),length(allt)]);
       rng = tstart:tend;

       % add prestim
       if ind(j)==1 
           % for 1st trial, no baseline available -- set to 0
           tc(j,:,i) = [zeros(1,prestim) allt(rng)];
       else
           % augment the range by previous [prestim] frames
           fullrng = rng(1)-prestim:rng(end);         
           tc(j,1:length(fullrng),i) = allt(fullrng);   
       end
       
       % remove baseline estimate, if selected
       if normBsl
           % estimate DC offset by prestim baseline vals
           DC = mean(tc(j,bslFrames,i));
           tc(j,:,i) = tc(j,:,i) - DC;
       end
   end 
end 

%%%%% get tcs, sems for each condition
tcs = zeros(length(frameWindow),nConds);
sems = zeros(length(frameWindow),nConds);

for i = 1:nConds
    tcs(:,i) = mean(tc(:,:,i))';
    sems(:,i) = std(tc(:,:,i))' ./ sqrt(nTrials);
end

%%%%% do t-tests of post-baseline v. baseline
Hs = NaN*ones(1,nConds);

for i = 1:nConds
    bsl = tc(:,bslFrames,i);
    peak = tc(:,peakFrames,i);
    [Hs(i) ps(i)] = ttest2(bsl(:),peak(:),alpha,-1);
    amps(:,i) = mean(peak,2) - mean(bsl,2);
end

%%%%% compute Signal-to-Noise Ratio
allBsl = tcs(bslFrames,:,:);
allPk = tcs(peakFrames,:,:);
if exist ('snrcond','var')
    SNR = abs(mean(allPk(:,snrcond)) - mean(allBsl(:,snrcond))) / std(allBsl(:,snrcond));
else    
    SNR = abs(mean(allPk(:)) - mean(allBsl(:))) / std(allBsl(:));
end

%%%%% compute relamps 
% the resulting matrix will be of size
% nTrials x nConds (have to shuffle things around)
relamps = fmri_relamps(permute(tc,[2 3 1]));

%%%%% assign everything to the output struct
anal.meanTcs = tcs;
anal.sems = sems;
anal.Hs = Hs;
anal.ps = ps;
anal.labels = labels;
anal.timeWindow = TR .* frameWindow;
anal.peakPeriod = [min(peakPeriod):TR:max(peakPeriod)];
anal.peakFrames=peakFrames;
anal.bslPeriod = TR .* bslFrames;
anal.amps = amps;
anal.relamps = relamps;
anal.SNR = SNR;
anal.SNRdb = 20 * log10(SNR);

% assign all time courses, but
% shuffle it into column former -- it's nicer
anal.allTcs = permute(tc,[2 1 3]);



return
