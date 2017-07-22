function [anal] = er_chopTSeriesMulti3D(view,coords,scans,varargin);
% [anal] = er_chopTSeriesMulti3D(view,[roi],[scans],[options]);
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
bslPeriod = -6:0;       % period to use as baseline in t-tests, in seconds
peakPeriod = 6:12;       % period to look for peaks in t-tests, in seconds
timeWindow = -6:22;     % seconds relative to trial onset to take for each trial
onsetDelta = 0;         % # secs to shift onsets in parfiles, relative to time course
snrConds = [];          % For calculating SNR, which conditions to use (if empty, use all)
waitbarFlag = 0;        % flag to show a graphical mrvWaitbar to show load progress


%%%%% get the parfile info
trials = er_concatParfiles(view,scans);
condNums = unique(trials.cond(trials.cond > 0));
whichconds=condNums;

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
        case 'whichconds', whichconds = varargin{i+1};    
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

%%%%% get the tSeries for each voxel / concat across scans
dt = viewGet(view,'curdt');
textstring=sprintf('Loading tSeries from %s datatype scans %d-%d...',dataTYPES(dt).name,min(scans),max(scans));
h = mrvWaitbar(0,textstring);

tSeries = [];
for s = 1:length(scans)
     raw = ~(detrendFlag(view,s));
    subt = getTseriesOneROI(view,coords,scans(s),raw);
    tSeries = [tSeries; subt{1}];
    mrvWaitbar(s/length(scans),h);
end

close(h)

%%%%% run the standard choptSeries analysis on each voxel


nVoxels = size(tSeries,2);
fprintf(1,'num voxels in view %s is %5d \n',view.viewType,nVoxels);

% jl101104 peak peropd 4:12 onset delta 0
% jv062004 onset delta=-4 peakPeriod 6:16 
% ras062304 onset delta=0 peakPeriod 6:14- 
% kgs080304  peak period 4:14 delta=0
% kgs061504 peak period 4:14 delta  onset=0
% skipped 3 frames adjusted par files;  use mc data
% ras 041702 6:14 offset -6 blocks of 16s
% js061504  4:12 onset 0 very noisy scan did not cover FFA

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add menus (3): Settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
defaults{1} = num2str(timeWindow);
defaults{2} = num2str(bslPeriod);
defaults{3} = num2str(peakPeriod);
defaults{4} = num2str(alpha);
defaults{5} = num2str(onsetDelta);
defaults{6} = num2str(whichconds);
defaults{7} = num2str(normBsl);
defaults{8}='y';
defaults{9}='y';
defaults{10}='n';

prompt{1} = 'Time Window, in seconds (incl. pre-stimulus onset period):';
prompt{2} = 'Baseline Period, in seconds:';
prompt{3} = 'Peak Period, in seconds:';
prompt{4} = 'Alpha for significant activation (peak vs baseline):';
prompt{5} = 'Shift onsets relative to time course, in seconds:';
prompt{6} = 'Which conditions to calculate reliability?';
prompt{7} = 'Normalize all trials during the baseline period? (0 for no, 1 for yes)';
prompt{8}=  'Plot matrix of all voxels amps [y/n]?';
prompt{9}=  'Conduct reliability analysis [y/n]?';
prompt{10}= 'Load tcUI for ROI data [y/n]?';
AddOpts.Resize = 'on';
AddOpts.Interpreter = 'tex';
AddOpts.WindowStyle = 'Normal';
answers = inputdlg(prompt,'Chop tSeries-Multi Settings...',1,defaults,AddOpts);
   
% exit if cancel is selected
if isempty(answers)
    return;
end

% parse the user responses / defaults
timeWindow = str2num(answers{1});
bslPeriod = str2num(answers{2});
peakPeriod = str2num(answers{3});
alpha = str2num(answers{4});
onsetDelta = str2num(answers{5});
whichconds = str2num(answers{6});
normBsl = str2num(answers{7});

if answers{8}=='y' | answers{8}=='Y'
    plotampsmat=1; 
else
    plotampsmat=0;
end

if answers{9}=='y' | answers{9}=='Y'
    reliability=1;
else
    reliability=0;
end
if answers{10}=='y' | answers{10}=='Y'
    tcUI=1;
else
    tcUI=0;
end
roiName=view.ROIs(selRoi).name;

h = mrvWaitbar(0,'Chopping tSeries...');
anal = er_chopTSeries3D(tSeries,trials,roiName,...
              'peakPeriod',peakPeriod,...
              'bslPeriod',bslPeriod,...
              'timeWindow',timeWindow,...
              'alpha',alpha,...
              'onsetDelta',onsetDelta,...
              'whichconds',whichconds,...
              'normBsl',normBsl,...
              'plotampsmat',plotampsmat);         
close(h)
% save data 
newdir=view.viewType;
cd (newdir)
dataTypedir=getDataTypeName(view);
cd (dataTypedir)

if ~exist('ROI4D')
        mkdir 'ROI4D'
end
cd ..    % newdir
cd ..    % data dir

anal.roiName=view.ROIs(selRoi).name;
whichconds
if reliability
    [rc,pc,rcov, pcov, odd, even]=pattern_analysis(anal.allamps(:,whichconds,:),anal.allampsminusDC(:,whichconds,:),anal.labels(whichconds),anal.roiName);
    anal.pc=pc;
    anal.rc=rc;
    anal.rcov=rcov;
    anal.pcov=pcov;
end

% too long but makes it platform insensitive
cd (newdir) 
cd (dataTypedir)
cd ('ROI4D')
filename=view.ROIs(selRoi).name;
eval (['save ' filename ' anal']);
fprintf(1, 'saved anal to %s/%s/ROI4D/%s.mat \n ', newdir,dataTypedir,filename);
cd ..
cd ..
cd ..
if tcUI
    fprintf(1, 'Loading mean ROI timecourse UI..........')
    tc = timeCourseUI(view,view.ROIs(selRoi).name,scans,dt);
end
return
