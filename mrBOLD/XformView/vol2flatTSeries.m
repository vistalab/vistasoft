function flat = vol2flatTSeries(gray,flat,selectedScans)
%
% function flat = vol2flatTSeries(gray,flat,[selectedScans])
%
% selectedScans: 
%   0 - do all scans
%   number or list of numbers - do only those scans
%   default - prompt user via selectScans dialog
%
% If you change this function make parallel changes in:
%    ip2volCorAnal, ip2volParMap, ip2volSpatialGradient, ip2volTSeries, 
%    vol2flatCorAnal, vol2flatParMap
%
% djh, 2/2001
%   mrErrorDlg('vol2flatTSeries not properly implemented yet. Do not use this function.'); 
% jw, 12/2009: implemented the mapping onto flat voxels 

% Don't do this unless gray is really a gray and flat is really a flat
if ~strcmp(gray.viewType,'Gray') | ~strcmp(flat.viewType,'Flat')
    myErrorDlg('vol2flatParMap can only be used to transform from gray to flat.');
end

% Check that both gray & flat are properly initialized
if isempty(gray)
    myErrorDlg('Gray view must be open.  Use "Open Gray Window" from the Window menu.');
end
if isempty(flat)
    myErrorDlg('Flat view must be open.  Use "Open Flat Window" from the Window menu.');
end
nScans = numScans(gray);

% (Re-)set scanList
if ~exist('selectedScans','var')
    selectedScans = selectScans(gray);
elseif selectedScans == 0
    selectedScans = 1:nScans;
end
if isempty(selectedScans)
  disp('Analysis aborted')
  return
end

% Check that dataType is the same for both views. If not, doesn't make
% sense to do the xform.
% because for example the two dataTypes may have a different number of
% scans.
[gray flat] = checkTypes(gray, flat); 

% Mask image for masking the flat map away from where we have data
mask = flat.ui.mask;

% open mrvWaitbar
waitHandle = mrvWaitbar(0,'Interpolating tSeries.  Please wait...');

% Intersect the coords from the gray view and the Flat view.
% See vol2flatCorAnal for details.
grayIndices=cell(1,2);
flatIndices=cell(1,2);
for h=1:2
    [grayCoordsTmp,grayIndicesTmp,flatIndicesTmp] = ...
        intersectCols(gray.coords,flat.grayCoords{h});
    grayIndices{h}=grayIndicesTmp;
    flatIndices{h}=flatIndicesTmp;
    % Error check on flatIndices.  Because the above code segment
    % is the same as that used to get the flat coords in
    % getFlatCoords, all of the flatIndices should be in the
    % intersection.  If not, something is busted.
    if length(flatIndicesTmp)~=size(flat.grayCoords{h},2)
        myWarnDlg('Ack!  Your flat maps do not appear to come from this segmentation!');
    end
    % Corresponding coords on the flat map
    coords{h} = flat.coords{h}(:,flatIndices{h});
end

% Loop through the scans
for scan = selectedScans
    % Load the gray tSeries
    grayTSeries = loadtSeries(gray,scan,1);
    
    % Count the number of frames
    nFrames = size(grayTSeries, 1);
    
    % Initialize the flat tSeries
    tSeries = nan(nFrames, size(mask,1)*size(mask,2));
    
    % Loop through hemispheres
    for h=1:2
        mrvWaitbar((h-1)/(2*length(selectedScans)) + (scan-1)/length(selectedScans));
        
        %Loop through the frames
       for f = 1:nFrames
           grayTSeriesTmp = grayTSeries(f,grayIndices{h});
           tSeriesTmp = myGriddata(coords{h}, grayTSeriesTmp.', mask(:,:,h));
           tSeries(f, :) = tSeriesTmp(:);
       end
        
        % Save tSeries
        % Should not be changed since this is called on a 'flat' view
        savetSeries(tSeries,flat,scan,h);
    end
end
close(waitHandle)
return

