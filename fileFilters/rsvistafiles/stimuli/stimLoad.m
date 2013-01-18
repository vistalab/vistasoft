function stim = stimLoad(stimFiles, varargin);
% Load files containing stimulus information into a stim struct.
%
% stim = stimLoad(stimFiles, <mr object or scan struct>);
%
%   or
%
% stim = stimLoad(stimFiles,secsPerScan,framePeriod);
%
% Stimulus files give information about event onset and type in
% an experiment, and may specify optional information like labels
% for the different event types (conditions) and colors associated
% with them for plotting purposes.
%
% Currently the only format supported is .par files (see
% parFormatDescription), but I may want to add support for other
% formats like BrainVoyager .prt files down the line.
%
% There are two ways to call stimLoad: (1) specifying the files and
% corresponding scans (either the mr files -- see mrFormatDescription --
% or scan struct -- see sessionAddScan); (2) specifying the seconds
% for each scan (secsPerScan), and the frame period (TR) at which data 
% were recorded.
%
% stimFiles: path to a .par file, or cell-of-paths to multiple parfiles.
%
% secsPerScan: Optional argument which can either be a single integer
% or an array the same size as the # of par files. This specifies how
% long the fMRI data associated with each par file is: the code will
% manually insert a null (condition 0) event at that time. 
%
% In place of a numeric matrix, you can also enter a scan struct (see
% sessionAddScan for a description) or a loaded mr struct
% (see mrFormatDesciption) to get the number of frames for a 
% time series.
%
%
% ras, 10/2005.
if nargin<2, help(mfilename); error('Not enough args.'); 
elseif nargin==2 % scan or mr struct specified
    mr = varargin{1};
    if ischar(mr) | iscell(mr), mr = mrParse(mr); end     
    TR = mr(1).voxelSize(4);
    secsPerScan = mr(1).extent(4); 
elseif nargin==3
    secsPerScan = varargin{1};
    TR = varargin{2};
end

% read in the stimulus files (get onsets in seconds, but not frames)
stim = stimReadPar(stimFiles, secsPerScan);

% add a field specifying event onsets in MR frames
stim.framePeriod = TR;
stim.onsetFrames = round(stim.onsetSecs/TR); 
for r = unique(stim.run)
    stim.framesPerRun(r) = min(secsPerScan, sum(stim.run==r));
end

% also get the condition names, numbers, and colors
stim.condNums = unique(stim.conds(stim.conds>=0));
useDefaultColors = 0;
for i = 1:length(stim.condNums)
    ind = find(stim.conds==stim.condNums(i));
    stim.condNames{i} = stim.labels{ind(1)};
    stim.condColors{i} = str2num(stim.colors{ind(1)});
    if isempty(stim.condColors{i})
        useDefaultColors = 1;
    end
end

% if any colors weren't assigned from the parfiles, switch
% to using the default color order
if useDefaultColors==1
    stim.condColors = tc_colorOrder(length(stim.condNums));
end

return
