function [VI XI YI SI allRSS] = rmLoadSearchSpace(view, roi);
% For a given ROI, compute the search space (variance explained across
% parameters x0, y0, and sigma major) for a selected set of voxels.
%
%  [VI XI YI SI allRSS] = rmLoadSearchSpace(view, [roi]);
%
% This function only works for the case where the grid search fits have
% been saved for all pRF fits. You can do this by replacing the call in
% rmGridFit.m (line 167 as of Jan 08 2009) from
%    s{n}=rmGridFit_oneGaussian(s{n},prediction,data,params,t);   
%
% to
%
%    s{n}=rmGridFit_oneGaussian_saveAll(s{n},prediction,data,params,t);   
%
% Then running a one Gaussian grid fit.
%
% INPUTS:
%	view: mrVista view. [Defaults to selected gray]
%	
%	roi: ROI specification (ROI structure, name, coords list, or index into
%	the view's ROIs). [Defaults to current ROI in view]
%
%
% OUTPUTS:
%
%   VI: variance explained as a 4D matrix of (y0 by x0 by sigma by voxels).
%   Each element of VI, (i, j, k, v), gives the proportion variance
%   explained for voxel v by a circular Gaussian pRF with parameters 
%   x0 = XI(i,j,k), y0 = YI(i,j,k), and sigma = SI(i,jk). 
%
%   XI: sampling grid of x0 parameters for the VI matrix.
%
%   YI: sampling grid of y0 parameters for the VI matrix.
%
%   SI: sampling grid of sigma parameters for the VI matrix.
%
%
%  Also note that this function is (a) slow and (b) memory intensive. I was
%  more interested in getting the function to work cleanly than optimizing
%  it when I wrote it. Perhaps this can be optimized down the line if it
%  gets used a lot.
%
%  SEE ALSO: rmLoadAllARSS, rmReshapeAllRSS. This function is essentially a
%  combination of the two, with some options locked in.
%
% ras,  12/2008.
if notDefined('view'),	view = getSelectedGray;		end
if notDefined('roi'),	roi = view.selectedROI;		end
if notDefined('method'),	method = 'linear';		end

%% check that a retinotopy model is loaded
model = viewGet(view, 'RMModel');
model = model{1};
params = viewGet(view, 'RMParams');


% does this model cover all voxels, or only an ROI?
if isequal( lower(params.wData), 'roi' )
    roiFlag = 1;
else
    roiFlag = 0;
end
    

%% get the path to the allRSS directory for this model
[p f ext] = fileparts(params.matFileName{1});
allRSSDir = fullfile(dataDir(view), ['AllRSS_' f(1:end-5)]); 

% check that it exists
if ~exist(allRSSDir, 'dir')
	error('Couldn''t find allRSS directory %s.\n', allRSSDir);
end

%% get the ROI indices into view.coords 
% (which corresponds to the indices in the saved AllRSS matrices)
% allow for the 'all' flag to load all saved voxels
roi = tc_roiStruct(view, roi);
if roiFlag==1
    % if the model was solved on an ROI, we can only take that subset of
    % coordinates in the provided ROI (the ROI for which we want to load
    % the search space) which also lie on the model's ROI
	if ~isempty(model.roi.coords)
		[roi.coords I] = intersectCols(model.roi.coords, roi.coords);
	else
		[iCoords I] = intersect(model.roi.coordsIndex, roiIndices(view, roi.coords));
		roi.coords = view.coords(:,iCoords);
	end
else
    % model was solved on 'all' data points (but may have been sparsely
    % sampled)
	I = roiIndices(view, roi.coords);
    
    % for coarse-to-fine searches, the model may not, in fact, have been
    % solved on all data points: the function rmCoarseSamples will
    % sub-select voxels from the volume to cut down on search time. So, we
    % can only keep those voxels in I which were within the search space
    if params.analysis.coarseSample==1
        availVoxels = find( rmCoarseSamples(view.coords, 1) );
        [ignore, I] = intersect(I, availVoxels);
    end
end
nVoxels = length(I);

if nVoxels==0
    error('No pRF data is available for the selected ROI and model.')
end


%% get the raw RSS for each voxel, for converting to var. exp.
if roiFlag==1
    % for a model solved within an ROI, we need to first select those
    % RSS values that lay within the model's ROI, then sub-select voxels
    % which also lay within the ROI the user provided.
    iRss = roiIndices(getSelectedGray, model.roi.coords);
    model.rawrss = model.rawrss(iRss);
end
rawrss = model.rawrss(I);

%% initialize the output variables
nFits = length(params.analysis.x0);
V = single( NaN(length(I), nFits-1) );

if nargout >= 5
    % initialize allRSS variable
    allRSS = [];
end

%% main loop: load RSS from all fits
w = dir( fullfile(allRSSDir, '*.mat') );
nFiles = length(w);
tic

fprintf('[%s]: Loading RSS for all fits...', mfilename);
for f = 1:nFiles
	fname = fullfile(allRSSDir, sprintf('allRSS_%i.mat', f));
	tmp = load(fname);
	
	% get the range of columns (a:b) in the output matrix 
	% for this file's data, as well as the # of input columns to take
	% (c) -- for the last file, we don't want all input columns
	if f==nFiles
		% for the last file, there will be some padding in the input matrix
		% (each saved matrix is nVoxel x stepSize, but we probably don't
		% have stepSize columns of data)
		a = tmp.stepSize * (f-1) + 1;
		b = nFits - 1;
		c = mod(nFits, tmp.stepSize) - 1; % -1: last fit not saved, for some reason...
	else
		a = tmp.stepSize * (f-1) + 1;
		b = tmp.stepSize * f;
		c = tmp.stepSize;
    end
    
	% the RSS values are scaled from 0-255 and saved as uint8. We need to
	% rescale them back to their original range.
    % first, it's possible (due to coarse fitting, etc) that one subset may
    % have no nonzero values -- in this case, tmp.dataRange is empy. Skip
    % this file in that case.
    if isempty(tmp.dataRange)
        continue
    end
    
    % now, given that we have data and a data range, rescale the numbers:
	cmd = sprintf('vals = rescale2( tmp.allRSS_%i(I,1:%i), [-32768 32767], [%s] ); ', ...
				  f, c, num2str(tmp.dataRange));
	eval(cmd);
	
    % hold on to allRSS if requested
    if nargout >= 5
        allRSS = [allRSS vals];
    end
    
	% convert to variance explained 
	V(:,a:b) = single( 1 - (vals ./ repmat(rawrss(:), [1 size(vals, 2)])) );
	
	fprintf('.');
end
fprintf('done. [%s]\n', secs2text(toc));

%%%%%% interpolate the variance explained values into a grid VI
nVoxels = size(V, 1);
% nVoxels = 4;

%% create the grid of parameter points
% xrng = unique(params.analysis.x0);
% yrng = unique(params.analysis.y0);
% srng = unique(params.analysis.sigmaMajor);
% [X Y S] = meshgrid(xrng, yrng, srng);
X = double(params.analysis.x0);
Y = double(params.analysis.y0);
S = double(params.analysis.sigmaMajor);

% again, the last data point seems not to be saved:
X = X(1:end-1);
Y = Y(1:end-1);
S = S(1:end-1);

%% now get the grid of points for the output matrix
[XI YI SI] = meshgrid(unique(X), unique(Y), unique(S));

% initialize the output matrix
VI = NaN( size(XI, 1), size(XI, 2), size(XI, 3), nVoxels );

%% loop across voxels and interpolate
for v = 1:nVoxels
	fprintf('Inerpolating voxel %i/%i...', v, nVoxels); 
	tic, 
    VI(:,:,:,v) = griddata3(X, Y, S, double(V(v,:)), XI, YI, SI, method); 
    fprintf('%s.\n', secs2text(toc));
end

% some points in the search space may produce a negative variance
% explained, because the prediction is inversely correlated with the data.
% We'll clip these at zero, for simplicity's sake:
VI(VI < 0) = 0;


return