function stim = er_concatParfiles(vw,scans);
% stim = er_concatParfiles(vw,[scans]);
%
% Reads in the parfiles assigned to the selected scans
% in view, concatenates them together, and returns the
% results in an stim struct.
%
% Fields of the stim struct:
%   'onsetSecs': onsets for each trial in seconds.
%   'cond': condition # of each trial
%   'label': text label, if any, specified for each trial
%   'run': run from which each trial was taken
%   'TR': the frame period of the scans
%   'parfiles': names of the parfiles from which the info was taken
%   'onsetFrames': onsets for each trial in fMRI frames.
%   'condNums': the unique #s used to specify different conditions in
%               the selected parfiles.
%   'condNames': The names for each condition, taken from the first
%                trial of each #
%
%
%
% 04/27/04 ras.
% 09/04 ras: made paths relative to HOMEDIR, so you don't have
% to be cd'd into it when you call this.
% 06/07 ras: added test for non-contiguous condition #s; if e.g. you
% specify conditions in a parfile as 4-8 (for instance for comparing w/
% other scans), and 1-3 are not assigned, will re-map the numbers to 1-4. 
% Also, removed the obsolete method of storing condition colors in the
% params field (you'll need to specify it in the .par files now).
global dataTYPES HOMEDIR;

if ~exist('vw', 'var') || isempty(vw), vw = getCurView; end

if (~exist('scans', 'var') || isempty(scans))
    [scans dt] = er_getScanGroup(vw);
    vw.curDataType = dt;
end

dt = vw.curDataType;
TR = dataTYPES(dt).scanParams(scans(1)).framePeriod;

stim.onsetSecs = [];
stim.cond = [];
stim.label = [];
stim.color = [];
stim.run = [];
stim.TR = TR;

for s = 1:length(scans)
    parList{s} = dataTYPES(dt).scanParams(scans(s)).parfile;
    if ~exist(parList{s}, 'file')
        % try appending .par
        [p f ext] = fileparts(parList{s});
        if isempty(ext), parList{s} = fullfile(p, [f '.par']); end
    end
    
    if ~exist(parList{s}, 'file')
        % probably relative to parfilesDir, try this:
        parList{s} = fullfile(parfilesDir(vw), parList{s});
    end
    
    if ~exist(parList{s}, 'file')
        error('Couldn''t find file %s. ', parList{s});
    end
end

stim.parfiles = parList;

for s = 1:length(scans)
    [onsets, conds, labels, colors] = readParFile(parList{s});
    
    % ignore all entries w/ negative time onsets, or negative cond #s
    stim.framesPerRun(s) = dataTYPES(dt).scanParams(scans(s)).nFrames;
    maxt = stim.framesPerRun(s) * TR;
    ok = find(conds>=0 & onsets>=0 & onsets<maxt);
    onsets = onsets(ok);
    conds = conds(ok);
    labels = labels(ok);
    colors = colors(ok);  
    
    % add a final entry specifying the last frame as cond 0
    conds(end+1) = 0;
    labels{end+1} = 'end of run';
    onsets(end+1) = (stim.framesPerRun(s)-1) * TR;
    if ~isempty(cellfind(colors)) 
        colors{end+1} = [0 0 0];
    end

    % increment onsets for scans after the first
    if s > 1
        framesInLastScan = dataTYPES(dt).scanParams(scans(s-1)).nFrames;
        onsets = onsets + stim.onsetSecs(end) + TR;
    end
    
    stim.onsetSecs = [stim.onsetSecs onsets];
    stim.cond = [stim.cond conds];
    stim.label = [stim.label labels];
    stim.color = [stim.color colors];
    stim.run = [stim.run s*ones(size(onsets))];
end

% convert to frame #s
stim.onsetFrames = round(stim.onsetSecs ./ TR); 
stim.onsetFrames = stim.onsetFrames + 1;

% also return the names of each unique
% condition # used, and the corresponding 
% labels for each condition
stim.condNums = unique(stim.cond(stim.cond>=0));
nConds = length(stim.condNums);
for i = 1:nConds
    ind = find(stim.cond==stim.condNums(i));
    stim.condNames{i} = stim.label{ind(1)};
    stim.condNames{i}(stim.condNames{i}=='_') = ' ';
end
stim.condNames = deblank(stim.condNames);

% for any blank condition names, assign a string with the number
unassigned = cellfind(stim.condNames, '');
for i = unassigned, stim.condNames{i} = num2str(stim.condNums(i)); end

% get condition colors:
% now, I've implemented two different ways to save this info. 
% one saves it in the event-related params, the other in the parfiles.
% I'd like to phase out the former way (from params), so use
% it only if it's set in params but not in the parfiles
% ras, 06/07: it's been a year, just removed the saving of cond colors
% in the params.
params = er_getParams(vw,scans(1));
if ~isempty(cellfind(stim.color))
    for i = 1:nConds
        ind = find(  stim.cond==stim.condNums(i) );
        stim.condColors{i} = stim.color{ind(1)};
    end

else
    stim.condColors = tc_colorOrder(length(stim.condNums));

end

% one last pass: check for leftover conds w/ unassigned colors
defaults = tc_colorOrder(nConds);
leftover = setdiff(1:nConds, cellfind(stim.condColors));
for i=leftover, stim.condColors{i} = defaults{i}; end


%% finally, check for non-contiguous condition #s: if any are missing
%% re-map from 1-N:
nonNull = stim.condNums(stim.condNums > 0);
if max(nonNull)~=length(nonNull) | min(nonNull)~=1,
    newRange = 1:length(nonNull);
    if any( ismember(stim.condNums, 0) )
        newRange = [0 newRange];
    end
    
    fprintf('[%s] Warning: non-contiguous condition #s found. \n', mfilename);
    fprintf('\tCond #s: %s \n', num2str(unique(stim.condNums)));
    fprintf('\tRemapping to: %s.\n', num2str(newRange));
    
    % re-map
    % (we set the values to negative values initially, to avoid conflict
    % between overlapping old and new numbers)
    for i = 1:length(newRange)
        old = stim.condNums(i);
        new = newRange(i);
        
        Iold = find(stim.cond==old);
        stim.cond(Iold) = -1 * new;
    end
    stim.cond = -1 .* stim.cond;  % flip back to positive values
    stim.condNums = newRange;       
end

return
