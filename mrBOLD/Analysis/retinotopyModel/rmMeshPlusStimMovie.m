function [M imgCmap] = rmMeshPlusStimMovie(vw, p, varargin)
% Create a movie combining the stimulus representation from the retinotopy
% model, and the projected BOLD response on the mesh.
%
%	[M imgCmap] = rmMeshPlusStimMovie(vw, p, varargin);
%
% INPUTS:
%
%	vw: gray view. Needs to have both a mesh loaded, and retiontopy model
%	parameters defined. The mesh images will be of the currently-selected
%	mesh, in its specified view.
%
%	params: structure with the following parameter fields:
%		'displayFlag': flag indicating whether and how to show the movie.
%		0 -- don't show;  1 -- show in MPLAY; 2 -- show in DISPLAYVOL. 
%		[default: 1, show in MPLAY]
%
%		'cothresh': minimum coherence value (or variance explained, if
%		you've run RMLOADDEFAULT) to show the responses.
%		[default: 0, no threshold]
%
%		'roiMask': name of an ROI mask. If provided, only activity in this
%		ROI will be shown. [default: no ROI]
%
%		'meanthresh': minimum mean map intensity in which to show the
%		response. [Default: 0, no threshold]
%
%		'cmap': color map to use when projecting activity. 
%		[default: mrvColorMaps('coolhot')]
%
%		'clim': color limits to scale the activity (in units of the
%		signal returned by percentTSeries, usually % signal change)
%		[Default: -3 3]
%
% params can be passed in as a struct, or as 'param', [value] pairs after
% the first two arguments. If no params are passed in either way, a dialog
% will come up.
%
% OUTPUTS:
%	M: 3D matrix with the movie images. For memory reasons, each frame of M
%	is a 2D indexed image (uint8 class), which indexes into the color map
%	returned as imgCmap.
%
%	imgCmap: color map for M.
%	
% ras, 04/2009.
if notDefined('vw'),		vw = getSelectedGray;			end
def = rmMeshPlusStimMovie_defaultParams(vw);

if notDefined('p')
	if isempty(varargin)
		p = rmMeshPlusStimMovie_paramsGUI(vw, def);
	else
		p = def;
	end
else
	p = mergeStructures(def, p);
end

%% parse options
for ii = 1:2:length(varargin)
	p.(varargin{ii}) = varargin{ii+1};
end

%% check that we have what we need
try
	msh = viewGet(vw, 'CurMesh');
catch
	error('No Mesh found in view.')
end

try
	params = viewGet(vw, 'RMParams');
catch
	error('No Retinotopy Model parameters found in view.')
end

dtName = getDataTypeName(vw);
scan = getCurScan(vw);

%% load / detrend the time series
vw = percentTSeries(vw, scan, 1);
nFrames = size(vw.tSeries, 1);


%% compute masks for data based on params
outsideROI = []; 
if ~isempty(p.roiMask)
	n = findROI(vw, p.roiMask);
	if n==0
		warning('Specified mask ROI %s not found. Ignoring...', p.roiMask);
	else
		I = roiIndices(vw, vw.ROIs(n).coords);
		outsideROI = setdiff(1:size(vw.coords, 2), I);
	end
end

lowMean = [];
if ~isempty(p.meanthresh) & p.meanthresh > 0
	try
		vw = loadMeanMap(vw);
	catch
		warning('Couldn''t load mean map. Ignoring mean threshold...')
	end
	lowMean = find(vw.map{scan} < p.meanthresh);
end

lowCo = [];
if ~isempty(p.cothresh) & p.cothresh > 0
	lowCo = find(vw.co{scan} < p.cothresh);
end
	
%% get the stimulus images
[params S] = rmStimulusMatrix(params, [], [], 0);
S = single(S);
asp = size(S, 2) / size(S, 1);  % aspect ratio
clear params

% if the user provided an example stim image, load this:
if ~isempty(p.stimImage) & exist(p.stimImage, 'file')
	exImg = single( imread(p.stimImage) );
end

%% make the movie
verbose = prefsVerboseCheck;
if verbose
	str = sprintf('Creating %.0f frame movie', nFrames);
	wbar = mrvWaitbar(0, str);
end

% set the color map options
vw.ui.displayMode = 'map';
vw.ui.mapMode.cmap = [gray(128); p.cmap];
vw.ui.mapMode.clipMode = p.clim;

for ii = 1:nFrames
	if verbose		% udpate mrvWaitbar
		str = sprintf('Creating frame %.0f of %.0f', ii, nFrames);
		fname{ii} = sprintf('Movie%0.4d.tiff', ii);
		mrvWaitbar(ii/nFrames, wbar, str);
	end
    
	%% get the mesh image for this time point
	% get amplitudes for this time point
	data = vw.tSeries(ii,:);
	
	% mask out regions specified by the thresholds
	if ~isempty(outsideROI), data(outsideROI) = 0;	end
	if ~isempty(lowMean), data(lowMean) = 0;		end
	if ~isempty(lowCo), data(lowCo) = 0;			end
		
	% plug in amplitudes for this time point into view
	vw.map{scan} = data;
	
	% update the mesh view with the colors for this time step
	meshColorOverlay(vw, 1);
    
	% grab the mesh image for this time point
    meshImg = single( mrmGet(msh, 'screenshot') / 255 );
	
	%% get the stimulus image for this time point
	stimImg = S(:,:,ii);
	stimImg = imresize(stimImg, round(size(meshImg, 1) .* [1 asp]));
	
	% if an example stim image is provided, mask it with the stim
	% representation
	if exist('exImg', 'var')
		stimImg = stimImg .* imresize(exImg, size(stimImg));
	end
	stimImg = repmat(stimImg, [1 1 3]); % -> truecolor

	%% write out this frame as an image
	img = cat(2, stimImg, meshImg);  clear stimImg meshImg
	imgPath = sprintf('Images/Mesh Plus Stimuli Frame %s %i.png', dtName, ii);
    if ~exist('Images', 'dir'), mkdir('Images'); end
	imwrite(img, imgPath, 'png');
	fprintf('Wrote file %s.\t[%s]\n', imgPath, datestr(now));
	
	%% composite the two images together
% 	M(:,:,:,ii) = cat(2, stimImg, meshImg);
	% the above runs out of memory easily. I should do tricks to make it
	% have a smaller footprint
	if ii==1
		% derive a color map for the compressed image from the first frame
		[M(:,:,ii) imgCmap] = rgb2ind(img, 256);
	else
		M(:,:,ii) = rgb2ind(img, imgCmap);
	end
end

if verbose, mrvWaitbar(1, wbar); close(wbar); end

%% display as requested
if p.displayFlag==1
	mplay(M);
elseif p.displayFlag==2
	displayVol(M, 1, imgCmap);
end

return
% /---------------------------------------------------------------/ %



% /---------------------------------------------------------------/ %
function p = rmMeshPlusStimMovie_defaultParams(vw);
% default parameters for this function.
p.displayFlag = 2;
p.cothresh = .1;
p.meanthresh = 0;
p.roiMask = [];
p.stimImage = [];
p.cmap = mrvColorMaps('coolhot', 128);
p.clim = [-3 3];
return
% /---------------------------------------------------------------/ %



% /---------------------------------------------------------------/ %
function p = rmMeshPlusStimMovie_paramsGUI(vw, def);
% dialog to allow the user to set params for this function.
dlg(1).fieldName = 'displayFlag';
dlg(end).style = 'popup';
dlg(end).list = {'don''t display' 'use MPLAY' 'use displayVol'};
dlg(end).value = def.(dlg(end).fieldName) + 1;
dlg(end).string = 'How to display movie?';

dlg(end+1).fieldName = 'cothresh';
dlg(end).style = 'number';
dlg(end).value = def.(dlg(end).fieldName);
dlg(end).string = 'Coherence (varexp) threshold?';

dlg(end+1).fieldName = 'meanthresh';
dlg(end).style = 'number';
dlg(end).value = def.(dlg(end).fieldName);
dlg(end).string = 'Mean map threshold?';

dlg(end+1).fieldName = 'roiMask';
dlg(end).style = 'popup';
if ~isempty(vw.ROIs)
	dlg(end).list = [{'(none)'} {vw.ROIs.name}];
else
	dlg(end).list = {'(none)'};
end
dlg(end).value = 1;
dlg(end).string = 'ROI to use as mask?';

dlg(end+1).fieldName = 'stimImage';
dlg(end).style = 'filename';
dlg(end).value = def.(dlg(end).fieldName);
dlg(end).string = ['Example stimulus image?' ...
				   '(the stim movie will show a ' ...
				   'masked version of this)'];

dlg(end+1).fieldName = 'cmap';
dlg(end).style = 'popup';
dlg(end).list = mrvColorMaps;
dlg(end).value = 'coolhot';
dlg(end).string = 'Color Map for Activation?';

dlg(end+1).fieldName = 'clim';
dlg(end).style = 'number';
dlg(end).value = def.(dlg(end).fieldName);
dlg(end).string = 'Color Scaling Limits for Activation?';

% put up dialog
[p ok] = generalDialog(dlg, mfilename);

if ~ok, error('User Aborted.'); end

% parse responses
if isequal(p.roiMask, '(none)'), 
	p.roiMask = '';
end
p.cmap = mrvColorMaps(p.cmap, 128);
p.displayFlag = p.displayFlag - 1;

return

