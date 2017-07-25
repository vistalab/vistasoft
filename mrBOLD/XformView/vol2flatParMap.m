function flat = vol2flatParMap(gray,flat,selectedScans,forceSave)
%
% function vol2flatParMap(gray,flat,[selectedScans],[forceSave])
%
% selectedScans: 
%   0 - do all scans
%   number or list of numbers - do only those scans
%   default - prompt user via chooseScans dialog
%
% forceSave: if entered as 1, will save the par map without prompting
% even if it already exists in the flat directory. Added this to 
% help with automated xformation of many maps.
%
% If you change this function make parallel changes in:
%    ip2volCorAnal, ip2volParMap, ip2volSpatialGradient, ip2volTSeries, 
%    vol2flatCorAnal, vol2flatTSeries
%
% djh, 2/2001, mrLoadRet-3.0
% ras, 5/2004, added forceSave argument
if ieNotDefined('forceSave')    forceSave = 0;      end

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
if isempty(gray.map)
    myErrorDlg('gray Parameter Map must be set.');
end

nScans = numScans(gray);

% (Re-)set scanList
if ~exist('selectedScans','var')
    selectedScans = chooseScans(gray);
elseif selectedScans == 0
    selectedScans = 1:nScans;
end
if isempty(selectedScans)
  disp('Analysis aborted')
  return
end

% Check that dataType is the same for both views. If not, doesn't make sense to do the xform.
% because for example the two dataTypes may have a different number of scans.
[gray flat] = checkTypes(gray, flat);

% Allocate space for the gray data arrays.
% If empty, initialize to cell array. 
% If non-empty, grab it so that it can be updated.
%
if ~isempty(flat.map) & strcmp(gray.mapName,flat.mapName)
    map = flat.map;
else
    map = cell(1,nScans);
end

% Mask image for masking the flat map away from where we have data
% (ras 05/06/04: make it if it's not made ... this is true for
% hidden flat views):
if ~isfield(flat.ui,'mask')    flat = makeFlatMask(flat);   end
mask = flat.ui.mask;

% Put up mrvWaitbar
waitHandle = mrvWaitbar(0,'Transforming Parameter Map.  Please wait...');

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
end

% Loop through the scans
for scan = selectedScans
    map{scan} = zeros(size(mask));
    
    % Loop through hemispheres
    for h=1:2
        mrvWaitbar((h-1)/(2*length(selectedScans)) + (scan-1)/length(selectedScans));
        
        if ~isempty(gray.map{scan})
            % Get the data corresponding to gray coords
            mapData = gray.map{scan}(grayIndices{h});
            
            % Corresponding coords on the flat map
            coords = flat.coords{h}(:,flatIndices{h});
            
            % Map the data
            % The operator .' is the NON-CONJUGATE transpose.  Very important.
            mapIm = myGriddata(coords,mapData.',mask(:,:,h));
          
            map{scan}(:,:,h) = mapIm;            
        end
    end
end
close(waitHandle)

% Set the fields in gray
if isfield(gray,'mapName')
    mname=gray.mapName;
else
    mname='';
end

% if isfield(flat.ui,'windowHandle') % test for hidden view
    flat = setParameterMap(flat,map,mname);
% end

% Save to file
saveParameterMap(flat,[],forceSave);

return;




