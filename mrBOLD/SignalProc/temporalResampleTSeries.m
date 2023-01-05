function vw = temporalResampleTSeries(vw, scan, newFramePeriod, dt)
% Temporally resample time series.
%
%   view = temporalResampleTSeries([view], [scan], [newFramePeriod=1.5], [dataType]);
%
% Written for combining pRF data acros sessions which had used different
% temporal sampling periods. This code adds the resampled time series as a
% new scan in the specified data type.
%
% INPUTS:
%	view: mrVista view. [default: cur view]
%	scan: scan(s) to resample. [default: cur scan]
%	newFramePeriod: frame period at which to resample the data. [default:
%					1.5 sec/frame]
%	dataType: name or index of data type in which to save the scan.
%			  [default: cur data type]
%
%
%
% ras, 09/2009.
if notDefined('vw'),				vw = getCurView;			end
if notDefined('scan'),				scan = vw.curScan;		end
if notDefined('newFramePeriod'),	newFramePeriod = 1.5;		end
if notDefined('dt'),				dt = vw.curDataType;		end

if length(scan) > 1
	% iteratively resample each scan
	for s = scan
		vw = temporalResampleTSeries(vw, s, newFramePeriod, dt);
	end
	return
end

%% compute the temporal sample points for the source and new time series
framePeriod  = viewGet(vw, 'FramePeriod', scan);
nFrames      = viewGet(vw, 'NumFrames', scan);
newNumFrames = nFrames * framePeriod / newFramePeriod;

t = [0:nFrames-1] .* framePeriod;
ti = [0:newNumFrames-1] .* newFramePeriod;

%% get ready
verbose = prefsVerboseCheck;

if verbose >= 1
	h_wait = mrvWaitbar(0, ['Resampling time series for scan ' num2str(scan)]);
end

nSlices = numSlices(vw);

%% main resampling stage
tSeriesFull = [];
dimNum = 0;

for slice = 1:nSlices
	src = loadtSeries(vw, scan, slice);
	
	nVoxels = size(src, 2);
	tSeries = single( NaN(newNumFrames, nVoxels) );

	for v = 1:nVoxels
		if any( isnan(src(:,v)) | isinf(src(:,v)) )
			continue;
		end
		
		tSeries(:,v) = interp1(t, src(:,v), ti);
		
		% interp1 introduces boundary errors: the last time point will be
		% NaNs. We will make it equal to the previous time point, so that
		% averaging this time series with other time series works.
		tSeries(end,v) = tSeries(end-1,v);
		
		if verbose >= 1
			mrvWaitbar((slice-1)/nSlices + v/(nSlices*nVoxels), h_wait);
		end
	end
	
	% save the time series
	[tgtView, tgtScan, tgtDt] = initScan(vw, dt, [], {vw.curDataType scan});
    dimNum = numel(size(tSeries));
	tSeriesFull = cat(dimNum + 1, tSeriesFull, tSeries); %Combine together

    % update the data type params -- including retinotopy model params if
	% they exist:
	mrGlobals;
	dataTYPES(tgtDt).scanParams(tgtScan).framePeriod = newFramePeriod;
	dataTYPES(tgtDt).scanParams(tgtScan).nFrames = newNumFrames;
	dataTYPES(tgtDt).scanParams(tgtScan).annotation = ...
		[dataTYPES(tgtDt).scanParams(tgtScan).annotation ' Resampled at '...
		 num2str(newFramePeriod) ' secs/frame'];
	 if checkfields( dataTYPES(tgtDt), 'retinotopyModelParams', 'framePeriod')
		 dataTYPES(tgtDt).retinotopyModelParams(tgtScan).framePeriod = newFramePeriod;
		 dataTYPES(tgtDt).retinotopyModelParams(tgtScan).nFrames = newNumFrames;
	 end
	saveSession;
end

if dimNum == 3
    tSeriesFull = reshape(tSeriesFull,[1,2,4,3]);
end %if

savetSeries(tSeriesFull, vw, tgtScan);


if verbose >= 1
	close(h_wait);
end


return
