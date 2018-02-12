function RFmovie = rmPlotReconstruction (v, setParams, varargin)
% RFmovie = rmPlotReconstruction (v, [setParams=0], [options])
%   
%   Purpose: 
%       Visualize the responses within an ROI to any scan in
%       stimulus-referred space. The stimulus referred space is created via
%       a retinotopic model, which gives an x, y, and sigma value to each
%       voxel. The model of each voxel's RF is then scaled to the voxel's
%       response   during each time point of the selected scan, and these
%       models are added together and plotted as a movie in stimulus space. 
% 
%   Note: works only in Gray view
%
%
%   OUTPUT
%       RFmov : a stimulus referred-movie of the scan
%
%   INPUT
%       v:           mrVista view structure
%       saveFlag:    boolean (if true, then save each movie frame as a jpg)
%       prf_size:    boolean (if true, use prf sigma to reconstruct, 
%                           if false assume fixed size for all pRFs)
%       fieldRange:  deg (size of visual field to plot)
%
%  
%
%   6/19/2008: JW wrote it, adpating from KA's rmPlotCoverage
%
%   7/3/2008: Several changes:
%        1. Divided the reconstruction at each time point and each point
%           in space by the total pRF coverage of that point in space. This
%           puts the movie in quasi % signal units.
%        2. Turned the default saveFlag to off
%        3. Arbitralily set the scale to +/- 3*max value in first TR. 

% Check the arguments and set defaults
if notDefined('v'), v = getCurView; end
if notDefined('setParams'),	setParams = 1;		end

%% default parameters
params.method = 'sum';
params.prf_size = 'from model'; 
params.fieldRange = 15;  
params.nSamples = 75;  
params.displayFlag = 1; 
params.cmap = jet(256);
params.scans = getCurScan(v);
params.normResponses = true;  
params.showStimulus = false;

if setParams
	% get parameters from a dialog
	[params ok] = rmPlotReconstructionParams(params);
    if ~ok, RFmovie = []; return; end
end

%% allow parameters to be passed as 'param', [value] pairs
for ii = 1:2:length(varargin)
	params.(varargin{ii}) = varargin{ii+1};
end

% Get pRF model
try
    rmModel   = viewGet(v,'rmSelectedModel');
    rmfname   = viewGet(v,'rmfile');
    [foo,rmfname,foo,foo] = fileparts(rmfname);   
catch
    error('Need to load retModel into curent view');
end

% get pRF params if needed (e.g., if we're overlaying the stimulus)
if params.showStimulus==1
	rmParams = rmRecomputeParams(v);
end

% Get ROI
try
     ROIcoords = getCurROIcoords(v);
     ROIname = v.ROIs(v.selectedROI).name;
catch
    error('Need to select ROI in GUI')
end

% Get scan
curScan = getCurScan(v);

% If cothresh is set in GUI, use it to restrict ROI
try
    co  = getCurDataROI(v,'co',curScan,ROIcoords);
    cothresh = viewGet(v, 'cothresh');
    ROIcoords = ROIcoords(:, co > cothresh);
end

% Get time series of ROI
% try
    [voxelTcs, ROIcoords] = voxelTSeries(v, ROIcoords, params.scans);
    voxelTcs( isnan(voxelTcs) ) = 0;
    [tmp indices] = intersectCols(v.coords, ROIcoords);
    nTRs = size(voxelTcs, 1);
    nVoxels = size(voxelTcs, 2);
	clear tmp
% catch
% 	fprintf('[%s]: last error: %s\n', mfilename, lasterr);
%     error('Need time series data for the current scan in the current view')
% end

% Get X, Y, and sigma for each voxel
subSize = rmModel.sigma.major(indices);
subX = rmModel.x0(indices);
subY = rmModel.y0(indices);

% reset pRF size?
if strcmp(params.prf_size, 'equal for every voxel')
   subSize=ones(size(subSize))*0.5;
end

% Set up stimulus-referred visual field
if params.showStimulus==1
	% we need to match the sampling grid specified by the model parameters,
	% otherwise we can't relate the stimulus and the amplitudes (or at
	% least, it's a much harder problem)
	[X Y] = prfSamplingGrid(rmParams);
else
	% use the params supplied by the user
	x = linspace(-params.fieldRange, params.fieldRange, params.nSamples);
	[X Y] = meshgrid(x, x);
end
mask = makecircle(size(X,1));


%% Build pRF for each voxel:
% for ROIs of >[step] voxels, we compute it in chunks to keep from running
% out of memory
step = 200; 
nVoxels = size(subSize, 2);

for iStart = 1:step:nVoxels
	rng = intersect([1:step] + iStart, 1:nVoxels);
	pRFs(:,rng) = rfGaussian2d( single(X(:)), single(Y(:)), ...
							single(subSize(rng)), single(subSize(rng)), ...
							single(0), single(subX(rng)), single(subY(rng)) );
end

% Plot the total coverage of the RF
RFcov = zeros(numel(X), 1);
for ii = 1:nVoxels
    thisModel = rfGaussian2d(single(X(:)), single(Y(:)), single(subSize(ii)), ...
								 single(subSize(ii)), single(0), ...
								 single(subX(ii)), single(subY(ii)));
    
	% combine pRFs using the selected method
	if isequal(lower(params.method), 'sum')
		RFcov = RFcov + thisModel;
	else
		RFcov = max(RFcov, thisModel); 
	end
	RFcov = flipud(RFcov);  % flip for display: +Y is UP not DOWN
	clear thisModel
end

RFcov = reshape(RFcov,[1 1].*sqrt(numel(RFcov)));
if params.displayFlag==2
	% Set up figure for MATLAB movie
	h = figure;
	subplot(1,2,1)
	imagesc (X(1,:), Y(:,1), RFcov .* mask);
	colormap(params.cmap);
	colorbar
	axis equal tight;
	title(['Visual field coverage of ', 'ROI ', ROIname]);
	
	subplot(1,2,2)
	headerStr = ['ROI ', ROIname,', scan ', num2str(curScan) ];
	set(h,'Name',headerStr)
else
	h_wait = mrvWaitbar(0, 'Creating Stimulus-Projected Activation Movie');
end

% Make movie 
for tr = 1:nTRs
    subResp = voxelTcs(tr,:);
	
	%% multiply the RFs for each voxel by the response at this time point
	% if there are few enough voxels, we can do this in one go. This can
	% cause an out-of-memory error, however; so if there are more than the
	% [step] threshold specified above, we do an inefficient-but-low-mem
	% FOR loop.
	if nVoxels <= step		
		% all in one go
		tmp = ones( size(pRFs, 1), 1, 'single' ) * subResp;
	    RF = sum(pRFs .* tmp, 2);

		% convert RF model from 1D to 2D
		RF = reshape(RF, [1 1] .* sqrt(numel(RF)));
	else
		% one voxel at a time
		RF = zeros(size(X));
		for v = 1:nVoxels
			RF = RF + reshape( subResp(v) * pRFs(:,v), size(X) );
		end
	end
	
	% flip RF for display: +Y is UP not DOWN
	RF = flipud(RF);
    
    % divide the movie by the coverage map to normalize (approximatley) to % signal  
    if params.normResponses == true, RF = RF ./ RFcov; end
    
    %set color range based on first image. this is kind of arbitrary but it
    %is nice to have a color range that is stable across the whole movie.
    if tr == 1,
        imMax = 3 * max(max(RF(:)), -min(RF(:)));
        imMin = -imMax;
	end
	
	%% create stimulus-referenced amplitude image for this frame
	img = RF .* mask;
	
	%% create the movie frame
	% the format of this frame depends on what sort of output we want
	if ismember(params.displayFlag, [1 3])
		% use MPLAY or export AVI: we want a 4-D movie matrix
		img = rescale2(img, [imMin imMax], [0 255]);
		
		if params.showStimulus==1
			stim = getCurStimImage(rmParams, tr, X);
% 			img = cat(3, img./255, img./255, stim);
			img = ind2rgb(img, params.cmap);
			img = img + repmat(stim, [1 1 3]);
			img(img > 1) = 1;
			img(img < 0) = 0;
			img = normalize(img, 0, 1);
		else
			img = ind2rgb(img, params.cmap);
		end
		
		% crop out the mask
		for z = 1:3
			tmp = img(:,:,z);
			tmp(~mask) = 0;
			img(:,:,z) = tmp;
		end
		
		RFmovie(:,:,:,tr) = img;	
		
		mrvWaitbar(tr/nTRs, h_wait);
		if tr==nTRs, close(h_wait); end
		
	elseif params.displayFlag==2
		%	Create a MATLAB movie: update with this frame
		figure(h); subplot(1,2,2)
		imagesc(X(1,:),Y(:,1), img, [imMin imMax])
		colorbar
		axis equal tight
		title([headerStr, ' TR ', num2str(tr)]);
		xlabel(rmfname);

		pos = get(h, 'Position');
		I = (getframe(h, [0 0 pos(3) pos(4)]));
		RFmovie(tr) = im2frame(I.cdata);
		
	end
	
end

%% display/export the final movie
switch params.displayFlag
	case 1, % play with MPLAY
		mov = mplay(RFmovie, 6);
		mov.play;
	case 2, % play MATLAB movie
		movie(RFmovie, 2);
		if ~exist(headerStr, 'dir')
			mkdir(headerStr)
		end
		fname = [headerStr filesep sprintf('foo%d.jpg', tr)];
		saveas(h, fname);
	case 3, % export to AVI
		aviSave(RFmovie);
end

return
% /------------------------------------------------------------------/ %



% /------------------------------------------------------------------/ %
function stimImage = getCurStimImage(rmParams, f, x)
% Get a stimulus image matching the sampling positions as the RF.

% account for the different stimuli that are shown next to each other
% f originally refers to the frame in the combined time series across scans:
% we want to break this down into scan n, frame f within that scan.
n = 1; 
nStimScans = numel(rmParams.stim);
while n <= nStimScans,
    tmp = f + rmParams.stim(n).prescanDuration;
    if tmp > size(rmParams.stim(n).images_org,2),
        f = tmp - size(rmParams.stim(n).images_org,2);        
        n = n + 1;
    else
        f = tmp;
        break;
    end
end

% stim image
stimImage     = NaN(size(x));
stimImage(rmParams.stim(1).instimwindow) = rmParams.stim(n).images_org(:,f);

stimImage = normalize(stimImage, 0, 1);

return
% /------------------------------------------------------------------/ %



% /------------------------------------------------------------------/ %
function [params ok] = rmPlotReconstructionParams(params);
%% dialog to get parameters for rmPlotCoverage.
dlg(1).fieldName = 'prf_size';
dlg(end).style = 'popup';
dlg(end).list = {'from model', 'equal for every voxel'};
dlg(end).string = 'pRF sigma';
dlg(end).value = params.prf_size;

dlg(end+1).fieldName = 'method';
dlg(end).style = 'popup';
dlg(end).string = 'Use sum or max method for pRF coverage map?';
dlg(end).list = {'sum' 'max'};
dlg(end).value = params.method;

dlg(end+1).fieldName = 'cmap';
dlg(end).style = 'popup';
dlg(end).string = 'Color map?';
dlg(end).list = mrvColorMaps;
dlg(end).value = 'jet';

displayOptionsList = {'MPLAY movie player' 'MATLAB figure' '.AVI file'};
dlg(end+1).fieldName = 'displayFlag';
dlg(end).style = 'popup';
dlg(end).string = 'Display movie format?';
dlg(end).list = displayOptionsList;
dlg(end).value = displayOptionsList{params.displayFlag};

dlg(end+1).fieldName = 'fieldRange';
dlg(end).style = 'number';
dlg(end).string = 'Visual Field Range (deg)?';
dlg(end).value = params.fieldRange;

dlg(end+1).fieldName = 'nSamples';
dlg(end).style = 'number';
dlg(end).string = 'Num Samples?';
dlg(end).value = params.nSamples;

dlg(end+1).fieldName = 'scans';
dlg(end).style = 'number';
dlg(end).string = 'Project which scans?';
dlg(end).value = params.scans;

dlg(end+1).fieldName = 'normResponses';
dlg(end).style = 'checkbox';
dlg(end).string = 'Normalize responses to visual field coverage?';
dlg(end).value = params.normResponses;

dlg(end+1).fieldName = 'showStimulus';
dlg(end).style = 'checkbox';
dlg(end).string = 'Overlay stimulus on responses?';
dlg(end).value = params.showStimulus;


[params ok] = generalDialog(dlg, mfilename);
if ~ok
    disp('User Aborted.')
    return
end

params.displayFlag = cellfind(displayOptionsList, params.displayFlag);
params.cmap = mrvColorMaps(params.cmap, 256);

return

