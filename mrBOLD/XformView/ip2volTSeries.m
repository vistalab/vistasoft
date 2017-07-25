function gray = ip2volTSeries(inplane,gray,selectedScans,method)
%
% function gray = ip2volTSeries(inplane,gray,[selectedScans],[method])
%
% Uses point sampling and nearest neighbor interpolation to map
% tSeries from inplane view to gray view. Inplane and
% gray views must already be open. Loads the inplane tSeries as
% it goes.
%
% Output tSeries matrices are (as usual) nFrames x nVoxels in size
% where nVoxels is the number of gray voxels that correspond to the
% inplanes, i.e., size(gray.grayCoords,2).
%
% selectedScans:
%   0 - do all scans
%   number or list of numbers - do only those scans
%   default - prompt user via selectScans dialog
% %
% method : 'nearest' [default], 'linear' interpolation
%
% If you change this function make parallel changes in:
%    ip2volCorAnal, ip2volParMap, ip2volSpatialGradient,
%    vol2flatCorAnal, vol2flatParMap, vol2flatTSeries
%
% djh, 2/2001
% ras, 10/2005, fixed to agree with a concomittant change in
% upSampleFactor.
% sod, 11/2005 added linear interpolation

% Don't do this unless inplane is really an inplane and gray is really a gray
if ~strcmp(inplane.viewType,'Inplane') || ~(strcmp(gray.viewType,'Gray') || strcmp(gray.viewType,'Volume'))
    myErrorDlg('ip2grayTSeries can only be used to transform from inplane to gray.');
end

% Check that both gray & flat are properly initialized
if isempty(inplane)
    myErrorDlg('Inplane view must be open.  Use "Open Inplane Window" from the Window menu.');
end
if isempty(gray)
    myErrorDlg('Gray view must be open.  Use "Open Gray Window" from the Window menu.');
end

% check for compatible data types
checkTypes(inplane,gray);

nScans = viewGet(gray, 'numScans');

% (Re-)set scanList
if ~exist('selectedScans','var') || isempty(selectedScans),
    selectedScans = er_selectScans(inplane);
elseif selectedScans == 0
    selectedScans = 1:nScans;
end
if isempty(selectedScans)
    disp('Analysis aborted')
    return
end

if nargin < 4,
    method = 'nearest';
end;
fprintf('[%s]: using %s interpolation.\n',mfilename,method);

% Size of the output tSeries matrices is: nFrames x nVoxels
% Also need to know number of inplane slices
nVoxels = size(gray.coords,2);

% open mrvWaitbar
verbose = prefsVerboseCheck;
if verbose,
    waitHandle = mrvWaitbar(0, 'Interpolating tSeries.  Please wait...');
end


% Tranform gray coords to inplane functional coords. Previously, the code
% to do this xform was duplicated in many functions, including this one.
% It is now a separate routine. The third argument when set to true returns
% the precise (non-integer) functional coords, which are interpolated
% below.
ipCoords = ip2volXformCoords(gray, inplane, true);

% Loop through the scans
for scan = selectedScans
    
    % Scale and round the grayCoords
    fprintf('Xforming scan %i ...\n',scan);
    
    % only round for nearest neighbor interpolation
    switch method,
        case 'nearest', ipCoords=round(ipCoords);
        case 'linear'
        otherwise,
            fprintf('Unknown interpolation method: %s\n',method);
            return
    end
    
    nFrames = viewGet(gray,'numFrames',scan);
    
    % Reset to NaNs
    tSeries = repmat(single(NaN), [nFrames nVoxels]);
    
    
    [~,nii] = loadtSeries(inplane,scan);
    funcData = niftiGet(nii, 'data');
    
    for frame = 1:nFrames
        subData = double(funcData(:,:,:,frame));
        tSeries(frame,:) = interp3(subData, ...
            ipCoords(2,:), ...
            ipCoords(1,:), ...
            ipCoords(3,:), ...
            method);
    end
    
    
    % Save tSeries
    % This should not need to be changed to new version because it is only
    % for the gray view
    savetSeries(tSeries, gray, scan, 1);
    
    % update the mrvWaitbar
    if verbose,
        mrvWaitbar(find(selectedScans==scan)/nScans, waitHandle);
    end
end %for

% close mrvWaitbar
if verbose, close(waitHandle); end

fprintf('Done xforming tSeries.\n');

return
