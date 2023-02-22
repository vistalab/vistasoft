function [data, params, coords] = rmLoadData(vw, params, slice, coarse, preserveCoords, scans)
% rmLoadData - load time series data for retinotopy experiment
%
% data = rmLoadData(view, params, [slice or roiIndex],[coarse],[preserveCoords], [scans]);
%
% INPUTS:
%   view: mrVista view
%   params: retinotopy params. The params.wData field determines
%           which data to load. This can be set to:
%               'all': load all data. [if slice is specified, will
%                                      load from that slice only.]
%               'fig': load data associated with figure. (rmPlot?)
%               'roi': load only the data for coordinates contained
%                       within an ROI. [If the roi index is specified
%                       as the 3rd argument, will load from that ROI;
%                       otherwise will load from the selected ROI,
%                       prompting the user to load one if none are
%                       loaded.]
%   [slice or roiIndex]: optional argument to select the
%    slice of data to load (params.wData = 'all') or ROI index in the
%    view (params.wData = 'roi').
%   coarse: ???
%	preserveCoords: flag to keep the order of voxels in the coordinates.
%	May make this slower.
%
% OUTPUTS:
%   data: time series data from selected voxels, format frames by voxels.
%         Converted into percent signal.
%   params: retinotopy params for the analysis. If loading data from
%         an ROI, attaches relevant coords and ROI name to params.coords
%         and params.roiName.
%
% 2006/01 SOD: wrote it.
% 2006/12 RAS: added optional ROI index, stores ROI name.
% 2008/09 RAS: returns coordinates of the data.
if nargin < 2,
	help(mfilename);
	return;
end;
if notDefined('coarse'),         coarse         = false; end;
if notDefined('slice'),          slice          = [];    end
if notDefined('preserveCoords'), preserveCoords = 0;     end


%-----------------------------------
% Place datasets behind each other. This is a rather crude way of
% stimultaneously fitting both. Due to this we cannot
% prewhiten (we could zeropadd/let the trends deal with this/not care).
% We also, average similar epochs so to save time later.
%-----------------------------------
data = [];
grayConMat = [];

if notDefined('scans')
    nScans = viewGet(vw, 'nScans');
    if nScans ~= length(params.stim)
        scans = er_selectScans(vw, ...
            sprintf('please choose %d scans for the model', length(params.stim)));
    else
        scans = 1:length(params.stim);
    end
end

for ds = 1:length(scans),
	scannum = scans(ds);
	switch lower(params.wData),
		case {'all'},
			tSeries  = loadtSeries(vw, scannum, slice);

			% get the coordinates for each time series
			if isequal( lower(vw.viewType), 'inplane' )
				dims = viewGet(vw,'Size');
				[X, Y, Z] = meshgrid(1:dims(2), 1:dims(1), 1:dims(3));
				coords   = [Y(:) X(:) Z(:)]';
			else
				% gray/volume view -- "coords"=indices in the view coords
				coords = 1:size(vw.coords, 2);
			end


			% average repeats
			tSeries  = rmAverageTime(tSeries ,params.stim(scannum).nUniqueRep);
            
            if coarse,
                % smooth
                [tSeries, grayConMat] = dhkGraySmooth(vw,tSeries,...
                    params.analysis.coarseBlurParams(1,:),grayConMat);
                
                % sparsely sample
                coarseIndex = rmCoarseSamples(viewGet(vw,'coords'),params.analysis.coarseSample);
                tSeries = tSeries(:,coarseIndex);
            end
            
            % convert to percent bold
            if params.analysis.calcPC
                tSeries  = raw2pc(tSeries);
            end
            
		case {'roi'}
			[tSeries, coords, params, grayConMat] = ...
				rmLoadDataROI(vw, params, ds, scannum, coarse, grayConMat, preserveCoords);

		otherwise,
			error('Unknown parameter wData (%s).',params.wData);
	end;

	% now make actual structure. On first run initialize entire data
	% structure and calculate the start and ending indices for each
	% iteration (stimulus)
	if isempty(data),
		dii.end   = cumsum([params.stim(scans).nFrames]./[params.stim(scans).nUniqueRep]);
		dii.start = [1 dii.end(1:end-1)+1];
		data = zeros(dii.end(end), size(tSeries ,2));
	end;
	% now put in data variables
	data(dii.start(ds):dii.end(ds),:) = tSeries;
    % data(dii.start(ds):144,:) = tSeries;
end;

return;
%---------------------------------


%---------------------------------
function data=raw2pc(data)
dc   = ones(size(data,1),1)*mean(data);
data = ((data./dc) - 1) .*100;
return;
%---------------------------------


%---------------------------------
function [tSeries, coords, params, grayConMat] = rmLoadDataROI(vw, params, ds, scannum, coarse, grayConMat, preserveCoords)
%% load the data from the selected ROI, regardless of view type.
% ras 09/2008: broken off into a separate function because the indentation
% was getting a bit extreme.

% get relevant ROI index, the 'slice' switch is not appropriate
% here. Because slice will always be defined. Thereby interfering
% with the selectedROI.
r = vw.selectedROI;

% get ROI coords
coords = vw.ROIs(r).coords;

% index into view's data
[coordsIndex, coords] = roiIndices(vw, coords, preserveCoords);
% do we want to recompute coords? this is good for gray views, in case ROI
% voxels are missing from the slice prescription. but might it cause
% problems for inplane models? 
%coordsIndex = roiIndices(view, coords, preserveCoords);

% store roi info
params = rmSet(params, 'roiName',   vw.ROIs(r).name);
params = rmSet(params, 'roiCoords', coords);
params = rmSet(params, 'roiIndex',  coordsIndex);

% coarse to fine switch
if coarse,
	% process everything, must do so for proper smoothing
	tSeries  = loadtSeries(vw, scannum);
	tSeries  = rmAverageTime(tSeries, params.stim(scannum).nUniqueRep);
	blurParams = params.analysis.coarseBlurParams(1,:);
	grayConMat = [];
	[tSeries, grayConMat] = dhkGraySmooth(vw, tSeries, blurParams, grayConMat);
	coarseIndex = rmCoarseSamples(rmGet(params,'roicoords'),params.analysis.coarseSample);

	% limit to roi
	%[c,ia] = intersectCols(view.coords,params.coords);
	roiIndex = rmGet(params,'roiIndex');
	tSeries  = tSeries(:,roiIndex(coarseIndex));

	% ras 01/09: only convert to percent change if the flag is set
	if params.analysis.calcPC, tSeries  = raw2pc(tSeries);	end

	coords = roiIndex(coarseIndex);

else % old approach
	if strcmpi(vw.viewType,'inplane'),   roiSlices = unique(coords(3,:));
    else                                 roiSlices = 1; end;

	tSeries  = [];

	% loop over slices and load data
	for roiSlice = roiSlices,
		vw.tSeriesSlice = roiSlice;
		vw.tSeriesScan  = scannum;
		vw.tSeries      = loadtSeries(vw, scannum, roiSlice);
		tSeries         = [tSeries getTSeriesROI(vw, coords, 1)];
	end;

	% ras 01/09: only convert to percent change if the flag is set
	if params.analysis.calcPC, tSeries  = raw2pc(tSeries);  end

	% average repeats
	tSeries  = rmAverageTime(tSeries, params.stim(scannum).nUniqueRep);
end;


return

