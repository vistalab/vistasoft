function [results, anal] = er_chopTSeriesMulti(view,coords,scans,varargin);
% [results, anal] = er_chopTSeriesMulti(view,[roi],[scans],[options]);
%
% Chop an event-related tSeries according to specified parfiles,
% separately for each voxel in an ROI.
%
% Returns two output structs. results is a struct with 
% certain summary statistics across voxels, such as the mean
% amplitudes for each condition and voxel, sems, etc. anal
% is a struct array containing one entry for each voxel. Each
% entry contains fields from er_chopTSeries (type
% help on that function for a list).
%
% Note: this does a minimal analysis only on each voxel, for 
% speed purposes, unless the 'fullanal' option is passed in. 
% In this case, calculations of SNR, fMRI relative amplitudes,
% and t-tests for significant activation are performed for 
% each voxel, which would not otherwise be performed. 
% Be warned, however, that the analysis could take twice to four 
% times as long.
%
% 08/04 ras.
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
barebones = 0;          % if 0, do full analysis; if 1, do minimal analysis
normBsl = 1;            % flag to zero baseline or not
alpha = 0.05;           % threshold for significant activations
bslPeriod = -8:0;       % period to use as baseline in t-tests, in seconds
peakPeriod = 4:12;       % period to look for peaks in t-tests, in seconds
timeWindow = -8:24;     % seconds relative to trial onset to take for each trial
onsetDelta = 0;         % # secs to shift onsets in parfiles, relative to time course
snrConds = [];          % For calculating SNR, which conditions to use (if empty, use all)
waitbarFlag = 0;        % flag to show a graphical mrvWaitbar to show load progress

%%%%% parse the options %%%%%
varargin = unNestCell(varargin);
for i = 1:length(varargin)
    if ischar(varargin{i})
        switch lower(varargin{i})
        case 'barebones', barebones = 1;
        case 'normbsl', normBsl = varargin{i+1};
        case 'alpha', alpha = varargin{i+1};
        case 'peakperiod', peakPeriod = varargin{i+1};
        case 'bslperiod', bslPeriod = varargin{i+1};
        case 'timewindow', timeWindow = varargin{i+1};
        case 'onsetdelta', onsetDelta = varargin{i+1};
        case 'snrconds', snrConds = varargin{i+1};
        case 'mrvWaitbar', waitbarFlag = 1;
        otherwise, % ignore
        end
    end
end

%%%%% check if the full analysis option is set
chk = 0;
for i = 1:length(varargin)
    if isequal(lower(varargin{i}),'fullanal')
        chk = 1;
        break;
    end 
end
if chk==0
    varargin{end+1} = 'barebones';
end

%%%%% get the parfile info
trials = er_concatParfiles(view,scans);

%%%%% get the tSeries for each voxel / concat across scans
h = mrvWaitbar(0,'Loading tSeries...');

tSeries = [];
for s = 1:length(scans)
	raw = ~(detrendFlag(view,s));
    subt = voxelTSeries(view,coords,scans(s),raw);
    tSeries = [tSeries; subt];
    
    mrvWaitbar(s/length(scans),h);
end

close(h)

%%%%% run the standard choptSeries analysis on each voxel
h = mrvWaitbar(0,'Chopping tSeries...');

nVoxels = size(tSeries,2);

for v = 1:nVoxels
    anal(v) = er_chopTSeries2(tSeries(:,v),trials,...
              er_getParams(view,scans(1)),...
              'peakPeriod',peakPeriod,...
              'bslPeriod',bslPeriod,...
              'timeWindow',timeWindow,...
              'normBsl',normBsl);
          % can probably remove the option flags down the line
          
    
    mrvWaitbar(v/nVoxels,h);
end

close(h)


%%%%% create some summary statistics
for v = 1:nVoxels
    if size(anal(v).amps)>1
        results.meanAmps(:,v) = mean(anal(v).amps)';
    else
        results.meanAmps(:,v) = anal(v).amps;
    end
    results.semAmps(:,v) = mean(anal(v).sems)';
    results.ampPVals(:,v) = anal(v).ps';
    results.allTcs(:,v) = anal(v).wholeTc';
    results.meanTcs(:,v,:) = permute(anal(v).meanTcs,[1 3 2]);
end

return