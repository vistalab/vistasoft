function vw = percentTSeries(vw, scanNum, sliceNum, detrend,...
    inhomoCorrection, temporalNormalization, noMeanRemove)
%Convert raw time series into percentage change from mean.
% vw = percentTSeries(vw, [scanNum], [sliceNum], [detrend], ...
%           [inhomoCorrection], [temporalNormalization], [noMeanRemove])
%
% Checks the tSeriesScan and tSeriesSlice slots to see if the
% desired tSeries is already loaded. If so, don't do anything.
% Otherwise:
% 1) loads tSeries corresponding to scanNum/sliceNum.
% 2) removes the DC and baseline trend of a tSeries.
% 3) sets:
%    vw.tSeries = resulting percent tSeries
%    vw.tSeriesScan = scanNum
%    vw.tSeriesSlice = sliceNum
%
% INPUTS
% ------
%   vw:             mrVista view structure 
%   scanNum:        integer scalar for scan number 
%                       [default = viewGet(vw, 'current scan')]
%   sliceNum:       integer scalar or vector for slice number 
%                       [default = viewGet(vw, 'current slice')]
%                       0: all slices: [1:viewGet(vw, 'num slices')]
%   detrend:        Options for how to remove the baseline:
%                       0: no trend removal
%                       1: highpass trend removal
%                       2: quadratic removal
%                      -1: linear trend removal
%                       [default: detrend = detrendFlag(vw,scanNum)]
%   inhomoCorrection: How to compensate for distance from the coil:
%                       0 do nothing
%                       1 divide by the mean, independently at each voxel
%                       2 divide by null condition
%                       3 divide by anything you like, e.g., robust
%                         estimate of intensity inhomogeneity
%                       For inhomoCorrection=3, you must compute the
%                           spatial gradient (from the Analysis menu) or
%                           load a previously computed spatial gradient
%                           (from the File/Parameter Map menu).
%   temporalNormalization: Boolean flag. If true, detrend each frame slice
%                           by slice so to that each frame has the same
%                           mean intensity. See doTemporalNormlalization
%                           [default = false]
%   noMeanRemove:       Hmm. Can someone explain this?
%
% OUTPUTS
% -------
%  vw:  Modified vw structure. The following fields get set in the vw:
%               tSeries, tSeriesScan, tSeriesSlice
%
% EXAMPLE
% -------
% dFolder = mrtInstallSampleData('functional', 'mrBOLD_01');
% cd(dFolder);
% vw = initHiddenInplane;
% vw = percentTSeries(vw, 1, 0);


% EDIT HISTORY:
% djh, 1/22/98
% arw, 12/05/99 Added option to remove quadratic function
% dbr, 8/1/00 Added high-pass baseline removal option
% dbr, 11/16/00 Made high-pass trend removal the default (detrendFlag = 1).
%               Linear trend removal is now detrendFlag = -1.
% djh, 11/00  Added option of dividing by spatialGradient
%             (estimate of intensity inhomogeneity) instead
%             of dividing by mean at each pixel.
% djh, 2/2001 Updated to mrLoadRet-3.0
%             Detrending is now done in detrendTSeries.m
%             This function now sets vw.tSeries (loadtSeries used to do this)
% djh, 9/28/2001 Subtract the mean (again) near the end to make sure it's zero
%             Otherwise, it messes up the correlation map.
% djh, 7/12/2002 Changed the options for inhomogeneity correction
%             Used to have only two options (0: divide by mean; 1: divide by robust est)
%             In the current code, current option 1 is the same as what used to be 0
%             and current option 2 is what used to be.
% dhb, 6/3/2003  Comment out code that checks slice and scan numbers and
%             assumes tSeries is cached if they match passed values.  This
%             check did not seem to be bulletproof.
% ras, 3/8/2007		reverted some changes suggested by Mark Schira about
%			  making singles. I agree to use single precision, but will
%			  make the change in loadtSeries and savetSeries, so that this
%			  code doesn't modify the input data type.


%% Argument check
if notDefined('scanNum'),               scanNum               = viewGet(vw,'current scan'); end
if notDefined('sliceNum'),              sliceNum              = viewGet(vw,'current slice'); end
if notDefined('detrend'),               detrend               = detrendFlag(vw,scanNum); end
if notDefined('inhomoCorrection'),      inhomoCorrection      = inhomoCorrectionFlag(vw,scanNum); end
if notDefined('temporalNormalization'), temporalNormalization = 0; end
if notDefined('noMeanRemove'),          noMeanRemove          = 0; end

if sliceNum == 0, sliceNum = 1:viewGet(vw, 'num slices', scanNum); end

%%
% load tSeries
tSeries = loadtSeries(vw, scanNum, sliceNum);

% also, if the tSeries is empty, return w/o erroring
if isempty(tSeries)
	vw = viewSet(vw, 'tSeries', []);
	vw = viewSet(vw, 'tSeriesScan', scanNum);
	vw = viewSet(vw, 'tSeriesSlice', sliceNum);
	return
end

nFrames = size(tSeries,1);

% Added by ARW
if (temporalNormalization)
	disp('Temporal normalization to first frame');
    tSeries=doTemporalNormalization(tSeries);
end

% Make the mean of all other frames the same as this.
% Divide by either the mean or the spatial gradient
%
switch inhomoCorrection
	case 0
		ptSeries = tSeries;
	case 1
		dc = nanmean(tSeries);
		dc(dc==0 | isnan(dc)) = Inf;  % prevents divide-by-zero warnings
		ptSeries = bsxfun(@rdivide, tSeries, dc);
	case 2
		myErrorDlg('Inhomogeneity correction by null condition not yet implement');
	case 3
		if ~isfield(vw, 'spatialGrad') || isempty(vw.spatialGrad)
			try
				vw = loadSpatialGradient(vw);
				updateGlobal(vw); % make sure it stays loaded
			catch                 %#ok<CTCH>
				myErrorDlg(['No spatial gradient map loaded. Either load '...
					'the spatial gradient map from File menu or edit ' ...
					'dataTypes to set inhomoCorrect = 0 or 1']);
			end
		end
		gradientImg = vw.spatialGrad{scanNum}(:,:,sliceNum);
		dc = gradientImg(:)';
		ptSeries = tSeries./(ones(nFrames,1)*dc);
	otherwise
		myErrorDlg(['Invalid option for inhomogeneity correction: ',num2str(inhomoCorrection)]);
end

% Remove trend
%
if detrend
	ptSeries = detrendTSeries(ptSeries,detrend,detrendFrames(vw,scanNum));
end

% Subtract the mean
% Used to just subtract 1 under the assumption that we had already divided by
% the mean, but now with the spatialGrad option the mean may not be exactly 1.
%
if noMeanRemove==0
	ptSeries = bsxfun(@minus, ptSeries, mean(ptSeries));
	% Multiply by 100 to get percent
	%
	ptSeries = 100*ptSeries;
end

% Set fields in view structure
vw = viewSet(vw, 'tSeries', ptSeries);
vw = viewSet(vw, 'tSeriesScan', scanNum);
vw = viewSet(vw, 'tSeriesSlice', sliceNum);


return



