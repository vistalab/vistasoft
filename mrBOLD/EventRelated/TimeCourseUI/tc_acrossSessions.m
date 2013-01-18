function [tc subjectTcs] = tc_acrossSessions(sessions, roi, p, varargin);
%
% [tc subjectTcs] = tc_acrossSessions(sessions, roi, [params], [options]);
%
% Run a time course UI for an ROI across several sessions,
% producing a combined across-subjects tc struct for the ROI,
% as well as some optional summary graphs along the way.
%
% All the ROIs must have the same (non-case-sensitive) name. If the roi
% argument is a cell array, will recursively call this function separately
% for each ROI.
%
% params is a struct with the following fields:
%   viewType: view type from which to take the time series data.
%             [default 'Inplane']
%   dataType: data type to use for each session. If a string, will use the
%           data type name for each session; if a number, the dt index;
%           if a cell array the same length as sessions, will assume you
%           are specifying a separate data type for each session. (Can also
%           be a vector of numeric indices for each session's data type.)
%           [default 'Original' for each session.]
%   scan:   one scan in the scan group from which to take the data. If a single
%           number is given, will use that scan for all sessions.
%           [default 1].
%   studyDir: directory which each session is relative to. [Defaults to pwd]
%           (this param doesn't matter if the sessions are full paths.)
%	volumeRoi: if this is set to 1, and the view type is Inplane,
%			will xform the ROI from the Volume/Gray shared ROI directory,
%			instead of using the Inplane ROI.
%	eventParams: event analysis parameters struct, specifying how to
%           process the tc struct in each session. If omitted/empty, will
%           apply the params for the first session to all subsequent
%           sessions. This ensures the analysis is consistent in each
%           session. [default empty, use first session].
%	groups: a set of arguments to use for grouping conditions together
%			during analyses (see tc_groupConditions).  Can either be a
%			cell array of condition groupings, or a nested cell array
%			containing the groups, names, and colors arguments for
%			tc_groupConditions.
%			E,g: groups = { {[1 2] [3 4]} {'group1' 'group2'} {'r' 'b'} };
%   sessionPlots:  cell array of plot types to show for each session
%           while concatenating. For each entry, will generate a
%           figure (or figures, for a large # of sessions) containing a
%           subplot for each session illustrating the data from that
%           session. Types of summaries reflect the tc_* functions that
%           govern the type of plot. They include:
%               'wholeTc': plot whole time course.
%               'meanTcs': mean time courses.
%               'amps': amplitudes +/- SEMs, according to the event-related
%               'ampType' field.
%               'meanAmps': peak-bsl difference amps.
%               'relAmps': dot-product relative amps.
%               'betas': GLM beta values.
%               'meanAmpsPlusTcs': plot mean amplitudes (according to the
%               'ampType' setting) and mean time courses side by side.
%               (Similar to the default view in the TCUI, but doesn't just
%               plot the difference amp)
%           [the default is 'meanAmpsPlusTcs']
%   titleType: field from which to choose the titles of session-specific
%       plots.  1 uses mrSESSION.sessionCode (usually the directory name); 2
%       uses mrSESSION.description (defined during initialization).  [default =
%       1]
%   savePlotsPath: optional directory in which to save the summary plots
%           (will save as .TIFFs). [default '', don't save]
%   cachePath: optional cache location. If empty, will automatically load
%           each session and recompute the time course. If nonempty, will
%           check for the cache file first; and if it exists, will load the
%           tc data from that file. Will also save each tc to that cache.
%           The cache path will save the combined tc as well as a
%           'subjectTcs' struct array, containing separate tcs for each
%           session. [default empty, don't cache]
%   methodFlag:  method to use when calling tc_combineTcs (run
%           help on that function to see the different options). [default
%           2, concatenate each session's whole time course]
%   openUI: flag for whether to open a time course UI for the combined tc.
%           [default 1, open TCUI].
%
% Instead of passing in a structure, params fields and values can be passed
% in as pairs of optional arguments following the params argument.
%
%
% EXAMPLES:
%   tc_acrossSessions({'ab010203' 'cd010405'}, {'RFFA' 'LFFA'});
%
%   sessions = {'sessA' 'sessB' 'sessC'};
%   tc_acrossSessions(sessions,'RV1',[],'dataType','MotionComp','scan',[1 2]);
%
% ras, 02/2007.
% ras, 04/2007: moved the tc_sessionPlots subfunction to be its own
% function.
% ras, 10/2007: added support for volumeRoi and groups parameters.
% kgs   3/2008  updates each tc amps according to params.ampType
%% Argument checks
if nargin < 2,    error('Not enough input arguments.');    end

if notDefined('p'), 
	p = tc_acrossSessionsDefault;       
else
	% allow the user to specify only some parameters, and fill the
	% rest in with default values
	p = mergeStructures(tc_acrossSessionsDefault, p);
end

tc = [];


%% parse options
for i = 1:2:length(varargin)
    p.(varargin{i}) = varargin{i+1};
end

%% check that each session exists
nSessions = length(sessions);
for s = 1:nSessions
    if ~exist( fullfile(p.studyDir, sessions{s}), 'dir' ) & ...
		~exist(sessions{s}, 'dir')
        error( sprintf('Session %s not found. ', sessions{s}) )
    end
end

if ~iscell(roi)
	roi = {roi};
end

% allow for one ROI for all sessions
for r = length(roi)+1:length(sessions)
	roi{r} = roi{r-1};
end

%% loop across sessions, getting tc data
for s = 1:nSessions
    cd( fullfile(p.studyDir, sessions{s}) );

    %% get current roi name    
    curroi = roi{s};

	
	%% get current data type and scan
	% data type can be specified as: a cell of names, a vector of indices,
	% or a single name/index for all sessions
    if iscell(p.dataType)
        dt = p.dataType{s}; 
    elseif isnumeric(p.dataType) & length(p.dataType)>1
        dt = p.dataType(s);
    else
        dt = p.dataType; 
    end

    if length(p.scan) > 1, scan = p.scan(s); else, scan = p.scan; end

    % initialize a hidden view of the appropriate view type, data type, etc
    V = feval( ['initHidden' p.viewType], dt, scan );
	
	% check if the selected data type exists
	if V.curDataType==0
		% should we error? Or skip this session?
		% for now, let's warn the user, but proceed, skipping this session.
		warning( sprintf('Data type %s not found for session %s', ...
						num2str(dt), pwd) )
		continue
	end

	%% load the ROI
	% if user requested to xform the ROI from volume, do that 
	% instead:
	if isequal(p.viewType, 'Inplane') & p.volumeRoi==1
		V = roiLoadVol2Inplane(V, curroi, 0);
	else
		V = loadROI(V, curroi);
	end

    % if ROI not found for this session, or empty ROI, skip this session
    if isempty(V.ROIs) | isempty(V.ROIs.coords)
        continue
    end
    
    if isempty(p.eventParams)  % should only occur if s==1
        p.eventParams = er_getParams(V);
    end

    tmpTc = tc_init(V); % load timecourse data based on view (V, which contains roi, dt, & scans info)     
	
	% set event-related params for this TC
	tmpTc.params = mergeStructures(tmpTc.params, p.eventParams);
	tmpTc = tc_recomputeTc(tmpTc, 1);
	
	
	% group conditions if requested
	if ~isempty(p.groups)
		if iscell(p.groups{1})
			groups = p.groups{1};
			names = p.groups{2};
			colors = p.groups{3};
		else
			groups = p.groups;
			names = {}; colors = {};
		end
		
		tmpTc = tc_groupConditions(tmpTc, groups, names, colors);
	end
	% if deconvolve then need to run deconvolution on each subject. Will
	% put the decovolved data into the meanTcs field.
	if tmpTc.params.glmHRF==0 %'deconvolve'
			if ~isfield(tmpTc, 'glm'), tmpTc = tc_applyGlm(tmpTc); end   
            % add a blank condition at the beginning betas are zero
            % because this is the baseline to which the glm is
            % estimated
             tmpTc.meanTcs = [zeros(tmpTc.glm.nh, 1) tmpTc.glm.betas]; % update mean tc to contain deconvolved data
    end
    if exist('subjectTcs', 'var')
		% check if this time course has a different temporal resolution to
		% the first time course. If so, resample
		if subjectTcs(1).TR ~= tmpTc.TR
			tmpTc = tc_resample(tmpTc, subjectTcs(1).TR);
		end

		subjectTcs(end+1) = tmpTc;
    else
        subjectTcs = tmpTc;
    end
end

% no subject tcs? warn the user and exit
if notDefined('subjectTcs')
	warning('ROI not found in any session!')
	subjectTcs = [];
	tcs = [];
	return
end

%% combine the time courses across sessions
tc = tc_combineTcs(subjectTcs, p.methodFlag);

%% produce figures of individual subjects responses if specified

if ~isempty(p.sessionPlots)
    if isfield(p, 'titleType')
        titleType = p.titleType;
    else
        titleType = 1;
    end

    for i = 1:length(p.sessionPlots)
        tc_sessionPlots(subjectTcs, p.sessionPlots{i}, titleType);
    end
end


%% produce TCUI of the average time course acrosss subjects if requested
if p.openUI==1
    tc_openFig(tc);
end



return
% /---------------------------------------------------------------------/ %



% /---------------------------------------------------------------------/ %
function p = tc_acrossSessionsDefault;
% default parameters for the across-sessions analysis.
p.viewType = 'Inplane';
p.dataType = 'Original';
p.scan = 1;
p.studyDir = pwd;
p.volumeRoi = 0;
p.eventParams = [];
p.groups = {};
p.sessionPlots = {'meanAmpsPlusTcs'};
p.savePlotsPath = '';
p.cachePath = '';
p.methodFlag = 4;
p.openUI = 1;
p.titleType = 1;
return
% /---------------------------------------------------------------------/ %



