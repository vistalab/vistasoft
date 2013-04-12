function [tSeries,nii] = loadtSeries(vw,scan,slice)
% Returns the tSeries data for a specified scan and slice.
% As well, this function now returns a nifti struct as an optional second
% return variable.
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
% AS, 04/2013, changed Inplane process to load nifti files

% Gray tSeries are stored differently, one per scan
% This is a bit ugly, but the only way to do it (for now). DJH
viewType = viewGet(vw,'View Type');
if strcmp(viewType,'Gray'),  slice = 1; end
if notDefined('scan'),  scan  = viewGet(vw, 'curScan'); end
if notDefined('slice'), slice = viewGet(vw, 'curSlice'); end

%Now loaded since we need dataTYPES for the file information
mrGlobals;

%We also need to decide which way to load the tSeries based on which view
%type we are in. If inplane, then we will need to load a nifti tseries. If
%gray, then we will need to load a matrix tseries file.

if strcmp(viewType,'Gray')
    
    %Original way of loading matrix files
    dirPathStr = fullfile(viewGet(vw,'tSeriesDir'),['Scan',int2str(scan)]);
    fileName   = fullfile(dirPathStr,['tSeries',int2str(slice)]);
    
    load(fileName,'tSeries');    % Load the variable tSeries
    nFrames = size(tSeries,1);   %#ok<NODEF>
    if (nFrames ~= viewGet(vw,'nFrames',scan))
        disp('loadtSeries: unexpected number of tSeries frames in file.');
    end
    nPixels = size(tSeries,2);
    
    %TODO: This should be getting the tSeries dimensions and not the Inplane
    % anat dimension.
    if (nPixels ~= prod(viewGet(vw, 'sliceDims', scan))) && ~(isequal(viewGet(vw,'View Type'),'Flat'))
        disp('loadtSeries: unexpected number of pixels in TSeries.');
    end
    tSeries = single(tSeries);
    
    
    nii = [];
    
elseif strcmp(viewType,'Inplane')
    
    dtNum = viewGet(vw,'Current Data Type');
    fileName = dtGet(dataTYPES(dtNum),'Inplane Path', scan);
    
    nii = niftiRead(fileName);
    
    %At this point, we will need to make the changes that we no longer make
    %in mrInit. Specifically - transform the nifti to the normal
    %orientation
    
    nii = niftiApplyAndCreateXform(nii,'Inplane');
    
    keepFrames = dtGet(dataTYPES,'Keep Frames');
    %Let's also implement keepFrames
    if ~isempty(keepFrames)
        nSkip = keepFrames(scan,1);
        nKeep = keepFrames(scan,2);
        if nKeep==-1
            % flag to keep all remaining frames
            nKeep = size(func.data, 4) - nSkip;
        end
        keep = [1:nKeep] + nSkip;
    end
    
    %Change the data and dimensions of the nifti
    data = niftiGet(nii,'Data');
    nii = niftiSet(nii,'Data', data(:,:,:,keep));
    dims = niftiGet(nii,'Dim');
    dims(4) = size(niftiGet(nii,'Data'), 4);
    nii = niftiSet(nii,'Dim',dims);
    
    %For backwards compatibility, let's also make the 'tSeries' data
    tSeries = single(niftiGet(nii,'Data'));
    
    %Now, let us take the tSeries data and transform it into the same
    %format as previously saved

    nSlices = dims(3);
    nFrames = dims(4);
    voxPerSlice = prod(mr.dims(1:2));
    
    for slice = 1:nSlices
        tSeries = squeeze(mr.data(:,:,slice,:)); % rows x cols x time
        tSeries = reshape(tSeries, [voxPerSlice nFrames])'; %#ok<NASGU> % time x voxels
    end
    
else
    %Neither an Inplane or a Gray view - error!
    error('tSeries:LoadTSeries','Loading tSeries using neither an Inplane nor Gray view.');
end

return

