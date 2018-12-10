function inplane = vol2ipParMap(volume,inplane, selectedScans,forceSave,method,noSaveFlag)
%
% inplane = ip2volParMap(volume, inplane,[selectedScans],[forceSave],[method],[noSaveFlag])
%
% Uses point sampling and nearest neighbor interpolation to map
% parameter map from volume view to  inplane view.  Inplane and
% volume views must already be open. See ip2VolParMap for inverse.
%
% forceSave: if entered as 1, will save the par map without prompting
% even if it already exists in the flat directory. Added this to
% help with automated xformation of many maps.
%
% noSaveFlag:  if 1, does not save out the interpolated map
%
% If you change this function make parallel changes in:
%   we don't have parallel functions yet, but could have functions like
%   these (in the vol2ip direction)
%    ip2volCorAnal, ip2volSpatialGradient, ip2volTSeries,
%    vol2flatCorAnal, vol2flatParMap, vol2flatTSeries
%
% CO & JW, 2016.01.14



if notDefined('forceSave'),   forceSave  = 0;           end
if notDefined('method'),      method     = 'nearest';   end;
if notDefined('noSaveFlag'),  noSaveFlag = 0;           end;
fprintf('[%s]: using %s interpolation.\n',mfilename,method);

% Don't do this unless inplane is really an inplane and volume is really a volume
if ~strcmp(viewGet(inplane, 'viewType'),'Inplane')
    myErrorDlg('ip2volParMap can only be used to transform from inplane to volume/gray.');
end
if ~strcmp(viewGet(volume, 'viewType'),'Volume') &&~strcmp(viewGet(volume, 'viewType'),'Gray')
    myErrorDlg('ip2volParMap can only be used to transform from inplane to volume/gray.');
end

% Check that both inplane & volume are properly initialized
if isempty(inplane)
    myErrorDlg('Inplane view must be open.  Use "Open Inplane Window" from the Window menu.');
end
if isempty(volume)
    myErrorDlg('Gray/volume view must be open.  Use "Open Gray/Volume Window" from the Window menu.');
end
if isempty(inplane.map)
    myErrorDlg('Inplane Parameter Map must be set. Use Load Parameter Map.');
end

nScans = viewGet(inplane, 'numScans');
% (Re-)set scanList
if ~exist('selectedScans','var') || isempty(selectedScans)
    ttl = 'Select scans to xform from inplane -> volume';
    selectedScans = er_selectScans(inplane, ttl);

elseif selectedScans == 0
    selectedScans = 1:nScans;

end

if isempty(selectedScans)
    disp('Analysis aborted')
    return
end

% Check that dataType is the same for both views. If not, doesn't make sense to do the xform.
% because for example the two dataTypes may have a different number of scans.
[inplane, volume] = checkTypes(inplane, volume);

% Allocate space for the inplane data arrays.
% If empty, initialize to cell array.
% If non-empty, grab it so that it can be updated.
%
if ~isempty(inplane.map) && strcmp(inplane.mapName,volume.mapName)
    map = inplane.map;
else
    map = cell(1,nScans);
end

% put up a mrvWaitbar, if consistent w/ VISTA 'verbose' preference
verbose = prefsVerboseCheck;
if verbose,
	waitHandle = mrvWaitbar(0,'Interpolating Parameter Map.  Please wait...');
end

% Transform inplane coords to volume coords. 
ip2VolCoords = ip2volXformCoords(inplane,volume);


% The parameter map from the gray view is a vector. To interpolate it to
% the functional inplane volume, it needs to be a volume. Here, we create
% an empty volume of the correct size (grayVol) and we derive the indices
% into this volume (volumeInds) that correspond to the vector paramter map.
% We will then create the volumetric parameter map inside the loop over
% scans because the map is different for each scan.
grayCoords = viewGet(volume, 'coords');
volumeSz   = viewGet(volume, 'anat size');
grayVol    = zeros(volumeSz);
volumeInds = sub2ind(volumeSz, grayCoords(1,:),grayCoords(2,:),grayCoords(3,:));

% After converting from volume to inplane anatomy, we will need to
% subsample to functional inplane. Here we compute the functional coords
% (functionalCoords) and the indices which take us from inplane coords to
% functional coords. 


functionalCoords = ip2functionalCoords(inplane, viewGet(inplane, 'coords'), ...
    [], true, false);


[functionalCoords, ip2funcIndices] = intersectCols(functionalCoords,functionalCoords);

% Loop through the scans and use interp3 to transform the values
% from the volume to the inplane. 
%
for curScan = selectedScans
    if verbose, mrvWaitbar((curScan-1)/nScans);  end

 
    mapVolume = viewGet(volume, 'map scan',curScan);
    if ~isempty(mapVolume)
        grayVol = grayVol*NaN;
        grayVol(volumeInds) = mapVolume;
        
        %ip2VolCoords = ip2VolCoords(:,ip2funcIndices);
        
       % interpolate gray view map to inplane
        mapInterpVol = interp3(grayVol,...
            ip2VolCoords(2,:),...
            ip2VolCoords(1,:),...
            ip2VolCoords(3,:),...
            method);
        
        % subsample inplane to functional
        mapSubsampleInterpVol = mapInterpVol(ip2funcIndices);
        
        % reshape map into a slab
        
        functionalIndices = sub2ind(dataSize(inplane), ...
            functionalCoords(1,:),functionalCoords(2,:),functionalCoords(3,:));
                       
        funcMap = NaN(dataSize(inplane));
        funcMap(functionalIndices) = mapSubsampleInterpVol;        
        %funcMap(functionalIndices) = mapInterpVol;


        
        map{curScan} = funcMap;
        clear tmp mapInplane mapInterpVol
    end
end

if verbose, close(waitHandle); end

inplane = setParameterMap(inplane, map, viewGet(volume, 'mapName'), viewGet(volume, 'mapUnits'));

% Set the fields in inplane
%
if checkfields(inplane,'ui','mapMode') && checkfields(volume,'ui','mapMode')
    inplane.ui.mapMode = volume.ui.mapMode;
end

% Save to file
if ~noSaveFlag
    saveParameterMap(inplane,[],forceSave,1);
end

return
