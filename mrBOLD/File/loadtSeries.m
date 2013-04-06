function tSeries = loadtSeries(vw,scan,slice)
% Returns the tSeries data for a specified scan and slice.
%
%       tSeries = loadtSeries(vw,scan,slice)
% 
% If scan or slice are not specified, then the routine uses the current
% scan or slice
%
% This routine handles various views
%
% DJH 1/9/98
% djh, 2/20/2001, removed interpolation, dumped dat files
% ras, 03/2007, moved to loading as single-precision

% Gray tSeries are stored differently, one per scan
% This is a bit ugly, but the only way to do it (for now). DJH
if strcmp(vw.viewType,'Gray'),  slice = 1; end
if notDefined('scan'),  scan  = viewGet(vw, 'curScan'); end
if notDefined('slice'), slice = viewGet(vw, 'curSlice'); end

dirPathStr = fullfile(viewGet(vw,'tSeriesDir'),['Scan',int2str(scan)]);
fileName   = fullfile(dirPathStr,['tSeries',int2str(slice)]);

%This will need to be changed to the loading of a nifti. Should tSeries
%then be changed to be a nifti rather than just data as well?

load(fileName,'tSeries');    % Load the variable tSeries
nFrames = size(tSeries,1);   %#ok<NODEF>
if (nFrames ~= viewGet(vw,'nFrames',scan))
    disp('loadtSeries: unexpected number of tSeries frames in file.');
end
nPixels = size(tSeries,2);

% size check:
% ras 05/13/05, made it not do this for flat tSeries, since these
% depend on the # of nodes, not the slice dims
%TODO: This should be getting the tSeries dimensions and not the Inplane
% anat dimension.
if (nPixels ~= prod(viewGet(vw, 'sliceDims', scan))) && ~(isequal(viewGet(vw,'View Type'),'Flat'))
    disp('loadtSeries: unexpected number of pixels in TSeries.');
end
tSeries = single(tSeries);

return

