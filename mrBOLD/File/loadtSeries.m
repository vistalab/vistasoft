function [tSeries,nii] = loadtSeries(vw,scan,slice)
% Returns the tSeries data for a specified scan and slice.
% As well, this function now returns a nifti struct as an optional second
% return variable.
%
%       tSeries = loadtSeries(vw,scan,slice)
%
% If scan or slice are not specified, then the routine uses the current
% scan or slice. For Inplane views, if slice is set to 0, then get data
% from all slices.
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

if strcmp(viewType,'Inplane')
    
    if slice == 0, slice = 1:viewGet(vw, 'num slices', scan); end

    dtNum = viewGet(vw,'Current Data Type');
    fileName = dtGet(dataTYPES(dtNum),'Inplane Path', scan);
    
    nii = niftiRead(fileName);
    
    %At this point, we will need to make the changes that we no longer make
    %in mrInit. Specifically - transform the nifti to the normal
    %orientation
    
    nii = niftiApplyAndCreateXform(nii,'Inplane');
    
    keepFrames = dtGet(dataTYPES(dtNum),'Keep Frames', scan);
    if numel(keepFrames) > 2
        keepFrames = keepFrames(scan,:);
    end
    %Let's also implement keepFrames
    if ~isempty(keepFrames)
        nSkip = keepFrames(1);
        nKeep = keepFrames(2);
        if nKeep==-1
            % flag to keep all remaining frames
            nKeep = size(niftiGet(nii,'Data'), 4) - nSkip;
        end
        keepFrame = [1:nKeep] + nSkip;
    else
        keepFrame = [1:size(niftiGet(nii,'Data'),4)];
    end
    
    %Change the data and dimensions of the nifti
    data = niftiGet(nii,'Data');
    nii = niftiSet(nii,'Data', data(:,:,:,keepFrame));
    dims = niftiGet(nii,'Dim');
    dims(4) = size(niftiGet(nii,'Data'), 4);
    nii = niftiSet(nii,'Dim',dims);
    
    %For backwards compatibility, let's also make the 'tSeries' data
    data = single(niftiGet(nii,'Data'));
    
    %Now, let us take the tSeries data and transform it into the same
    %format as previously saved
    
    nFrames = dims(4);
    voxPerSlice = prod(dims(1:2));
    nSlices = length(slice);
    
    tSeries = data(:,:,slice,:); % limit to selected slices
    tSeries = permute(tSeries, [4 1 2 3]); % time x rows x cols x slice
    tSeries = reshape(tSeries, [nFrames voxPerSlice  nSlices]); % time x voxels x slice
    
elseif strcmp(viewType,'Gray')
    
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
    
    
end

return

