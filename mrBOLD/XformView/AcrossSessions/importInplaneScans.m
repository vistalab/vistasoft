function [vw, xform] = importInplaneScans(vw, srcSession, srcDt, srcScans, tgtDt, manualAlign);
% Import time series, maps, corAnals, and param maps from a source
% session into the current session, saving interpolated functionals in the 
% Inplane view of the target time series.
%
% view = importInplaneScans(<view>, <srcSession, srcDt, srcScans>, <tgtDt>, <manualAlign=1>);
%
% This may or may not be a good idea. The benefits of this approach, versus
% transforming all data into the volume/gray views (see IMPORTSCANS),
% include the creation of 3D data matrices which can be made into movies,
% so users can visually inspect the functional alignment across sessions;
% the ability to run analyses on large across-session data sets (GLMs, etc)
% on a slice-by-slice basis, and without upsampling to the volume resolution,
% to save memory footprints, and the ability to have a consistent analysis
% pathway across sessions, where everything can be analyzed in the inplane
% orientation first, then the results xformed to the volume.
%
% Downsides include possibly lower-quality registration, since the
% alignment is done at the lower functional resolution, and missing data:
% since only the subset of the source data which maps to the target
% inplanes is taken, some of the source data may be left behind. This would
% not be the case if all the data are mapped to the volume for both
% sessions.
%
% To use this function, both the source and target functional sessions
% should be aligned to the same volume anatomy. The code solves a mapping
% from the source inplane coordinates to the target volume coordinates using 
% the saved alignments:
%	targetToSourceXform = inv(volToSrcXform) * targetToVolXform;
% (note that we go from target to source in this mapping, so we can find
% the corresponding points FROM our given target coordinates to the source
% coordinates, then linearly interpolate the source data.)
%
% This function also allows the user to use the mrRx tools to perform a
% final manual alignment step, to verify the mapping between sessions. This
% alignment is set using the 'manualAlign' input argument. Possible values
% are:
%	0: no manual alignment/verification. The code automatically saves the
%	time series, relying solely on the existing alignments. (Not
%	recommended).
%
%	1: compare the functionals between sessions: the mean map of the first
%	selected target scan is compared to the mean map from the first scan
%	for the target view. Provides a direct view of the data which will be
%	interpolated, although distortions caused by day-to-day variations in
%	scanner gradients, as well as lower resolution, may make verifying this
%	alignment tricky.
%
%	2: compare the inplanes between sessions: the inplane anatomicals
%	between the two sessions are compared. This may allow for a better
%	visual inspection of session-to-session coregistration, although it
%	relies on a good functional-to-inplane alignment within each session.
%
% 
% ras, 07/2009.
mrGlobals; % declares global mrSESSION variable
if isempty(mrSESSION), loadSession; end

if notDefined('vw'),  vw = getSelectedGray;      end

if notDefined('srcSession')
    studyDir = fileparts(HOMEDIR);
    srcSession = selectSessions(studyDir,1);
    srcSession = srcSession{1};
end

% load source mrSESSION file
src = load(fullfile(srcSession,'mrSESSION.mat'));

if notDefined('srcDt')
    % select from src session's data types
    names = {src.dataTYPES.name};
    [srcDt, ok] = listdlg('PromptString','Import from which data type?',...
        'ListSize',[400 600],...
        'SelectionMode','single',...
        'ListString',names,...
        'InitialValue',1,...
        'OKString','OK');
    if ~ok, return; end
end

% make sure specification format is clear:
% srcDt will refer to the data type name, and
% srcDtNum will be the numeric index into dataTYPES:
if ~isnumeric(srcDt)
    srcDtNum = existDataType(srcDt, src.dataTYPES);
else
    srcDtNum = srcDt;
    srcDt = src.dataTYPES(srcDtNum).name;
end

% error check: the source data type should exist
if srcDtNum==0
    error(sprintf('Data type %s doesn''t exist.',srcDt))
end

if notDefined('srcScans')
    % select from src session/dt's scans
    src = load(fullfile(srcSession,'mrSESSION.mat'));
    names = {src.dataTYPES(srcDtNum).scanParams.annotation};
    for i = 1:length(names)
        names{i} = sprintf('Scan %i: %s',i,names{i});
    end
    [srcScans, ok] = listdlg('PromptString','Import which scans?',...
        'ListSize',[400 600],...
        'SelectionMode','multiple',...
        'ListString',names,...
        'InitialValue',1,...
        'OKString','OK');
    if ~ok, return; end
end

if notDefined('tgtDt')
    % get from dialog
    dlg(1).fieldName = 'existingDt';
    dlg(1).style = 'popup';
    dlg(1).string = 'Target Data Type for imported scans?';
    dlg(1).list = {dataTYPES.name 'New Data Type (named below)'};
    dlg(1).value = vw.curDataType;

    dlg(2).fieldName = 'newDtName';
    dlg(2).style = 'edit';
    dlg(2).string = 'Name of new data type (if making a new one)?';
    dlg(2).value = '';

    [resp, ok] = generalDialog(dlg, 'Import Scans');
    if ~ok, return; end

    if ismember(resp.existingDt, {dataTYPES.name})
        tgtDt = resp.existingDt;
    else
        tgtDt = resp.newDtName;
    end
    %
    %     q = {'Name of the data type in which to save imported data?'};
    %     def = {['Imported_' srcDt]};
    %     resp = inputdlg(q, mfilename, 1, def);
    %     tgtDt = resp{1};
end

%% get an initial alignment 
% this comes from the saved alignments from each session
xformSrc = src.mrSESSION.alignment;
xformTgt = mrSESSION.alignment;

% Logic: mrSESSION.alignment is the inplane -> vol xform.
% That is, volCoords = mrSESSION.alignment * ipCoords.
% We want to map known target ipCoords to source ipCoords.
% For this, we need:
%   srcIpCoods = inv(tgtIp2VolXform) * (srcIp2VolXform) * tgtIpCoords;
xform = inv(xformTgt) * xformSrc;

%% do the manual alignment step if requested
if manualAlign == 1
	xform = importInplanes_getManualAlign(vw, xform, srcSession, src, tgtDt);
end


%% import the time series




return
% /--------------------------------------------------------------------/ %



% /--------------------------------------------------------------------/ %
function xform = importInplanes_getManualAlign(V, xform, srcSession, src, tgtDt);
%% Set / adjust the inplane to inplane alignment manually using mrRx.
%% We want this to be maximally flexible, so we will load both the inplane
%% anatomies, and the mean functionals, from each session, for comparison.
%% The source and target data may have different data sizes. We resample
%% the source data to match the target data, so that the resulting xform
%% maps from taraget IP coords -> source IP coords, for all target IP
%% coords. (When we use this xform to import data, we'll mask out data
%% falling outside the source inplanes.)
mrGlobals;
global STATE ipSrc ipTgt mapSrc mapTgt;

%% (1) get sizes of each of the main data matrices
srcNSlices = src.mrSESSION.inplanes.nSlices;
srcFuncSize = [src.mrSESSION.functionals(1).cropSize srcNSlices];
srcAnatSize = [src.mrSESSION.inplanes.cropSize srcNSlices];

tgtFuncSize = dataSize(V, 1);
tgtAnatSize = viewGet(V,'Size');
				
srcRes = src.mrSESSION.inplanes.voxelSize;
tgtRes = mrSESSION.inplanes.voxelSize;


%% (2) get inplanes from source session
ipPath = fullfile(srcSession, 'Inplane', 'anat.mat');
load(ipPath, 'anat');

% resample to match target inplanes, if needed
if (isequal(srcAnatSize, tgtAnatSize) && isequal(srcRes, tgtRes))
	% they're the same? great! just take the anatomy directly.
	ipSrc = anat;
else
	% we interpolate the source inplanes into the target space, assuming
	% an identity transformation: that is, they start out centered at the
	% same point. (When the user aligns them, the xform will reflec the
	% true set of translations and rotations required.)
	resampXform = eye(4);  % standard identity matrix
	
	% adjust for the different resolutions (adjust diagonal)
	resampXform([1 6 10]) = tgtRes ./ srcRes;
	
% 	% add translations to center it
% 	resampXform(1:3,4) = -(srcAnatSize - tgtAnatSize) ./ 2;
	
	% we center the rx at 0,0,0 to rotate about the
	% center (see also rxAlign).
	shift = [eye(3) -tgtAnatSize([2 1 3])' ./ 2; 0 0 0 1];
	resampXform = inv(shift) * resampXform * shift;
	
	% xform tgt coords into source anat space
	[Y, X, Z] = meshgrid(1:tgtAnatSize(2), 1:tgtAnatSize(1), 1:tgtAnatSize(3));
	tgtCoords = [Y(:) X(:) Z(:) ones(size(X(:), 1), 1)]';  
	clear X Y Z
	
	srcCoords = resampXform * tgtCoords;
	clear tgtCoords
	
	ipSrc = myCinterp3(anat, srcAnatSize(1:2), srcAnatSize(3), ...
						srcCoords(1:3,:)', 0);
	ipSrc = reshape(ipSrc, tgtAnatSize);
end

%% (3) get mean map from the source session
meanMapFile = fullfile(srcSession, 'Inplane', 'Original', 'meanMap.mat');
if ~exist('meanMapFile','file')
	cd(HOMEDIR);
	callingDir = pwd;
	
	cd(srcSession);
	loadSession;
	computeMeanMap(initHiddenInplane('Original'), 0, 1);
	
	cd(callingDir);
	HOMEDIR = wd;
	loadSession;
end	
load(meanMapFile, 'map');

% resample mean map:
% we interpolate the source mean map into the target space, assuming
% they start out centered at the same point. 
resampXform = eye(4);  % standard identity matrix

% adjust for the different resolutions
resampXform([1 6 10]) = (srcFuncSize ./ srcAnatSize) .* (tgtRes ./ srcRes);

% % add translations to center it
% resampXform(1:3,4) = -(srcAnatSize - tgtAnatSize) ./ 2;

% we center the rx at 0,0,0 to rotate about the center (see also rxAlign).
shift = [eye(3) -tgtAnatSize([2 1 3])' ./ 2; 0 0 0 1];
resampXform = inv(shift) * resampXform * shift;

% xform tgt coords into source anat space
[Y, X, Z] = meshgrid(1:tgtAnatSize(2), 1:tgtAnatSize(1), 1:tgtAnatSize(3));
tgtCoords = [Y(:) X(:) Z(:) ones(size(X(:), 1), 1)]';  
clear X Y Z

srcCoords = resampXform * tgtCoords;
clear tgtCoords

mapSrc = myCinterp3(map{1}, srcFuncSize(1:2), srcFuncSize(3), ...
					srcCoords(1:3,:)', 0);
mapSrc = reshape(mapSrc, tgtAnatSize);

% (4) get inplanes from target session
ipPath = fullfile(HOMEDIR, 'Inplane', 'anat.mat');
load(ipPath, 'anat');
ipTgt = anat;

% (5) get resampled mean map from the target session
meanMapFile = fullfile(HOMEDIR, 'Inplane', 'Original', 'meanMap.mat');
if ~exist('meanMapFile','file')
	computeMeanMap(initHiddenInplane('Original'), 0, 1);
end	
load(meanMapFile, 'map');

% resample mean map
mapTgt = NaN(tgtAnatSize);
for slice = 1:srcFuncSize(3)
	im = map{1}(:,:,slice);
	im = rescale2(im, [], [0 255]);
	mapTgt(:,:,slice) = imresize(im, tgtAnatSize(1:2));
end


%% (6) call mrRx
rx = mrRx(ipSrc, ipTgt, 'volRes', tgtRes, 'refRes', tgtRes, 'rxRes', tgtRes);

% rx = rxOpenCompareFig(rx);

%% set the initial xform
rx = rxSetXform(rx, xform);
rx = rxStore(rx, 'Auto-alignment');

%% add special buttons for this step
% one button switches between inplane and mean maps, the other button is a
% 'GO' button to proceed with the importing. Closing mrRx any other way
% cancels the process.

% GO -- callback
cb = ['rx = get(gcf, ''UserData''); ' ...
	  'xform = rx.xform; ' ...
	  'rxClose(rx); uiresume; '];
  
% make the button  
uicontrol('Style', 'pushbutton', 'Units', 'normalized', ...
          'Position',[.18 .42 .18 .15], 'String', 'Use This Xform', ...
          'BackgroundColor', [.4 1 .8], 'ForegroundColor', 'k', ...
          'Tag', 'OK', 'Callback', cb);
	  
% switch inplanes and mean map -- callback
STATE = true;
cb = ['global STATE ipSrc ipTgt mapSrc mapTgt; ' ...
	  'STATE = ~STATE; ' ...
	  'rx = get(gcf, ''UserData''); ' ...
	  'if STATE, rx.vol = ipSrc;  rx.ref = ipTgt; ' ...
	  'else, rx.vol = mapSrc;  rx.ref = mapTgt; ' ...
	  'end; ' ...
	  'rxRefresh(rx); clear rx; '];
  
% make the button  
uicontrol('Style', 'pushbutton', 'Units', 'normalized', ...
          'Position',[.18 .62 .18 .12], 'String', 'Switch Inplane / Mean Map', ...
          'BackgroundColor', [.7 .7 .7], 'ForegroundColor', 'k', ...
          'Tag', 'OK', 'Callback', cb);

	  
	  
%% wait for user response
uiwait;

return
