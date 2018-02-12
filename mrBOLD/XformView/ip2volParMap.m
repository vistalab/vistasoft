function volume= ip2volParMap(inplane,volume,selectedScans,forceSave,method,noSaveFlag)
%
% volume= ip2volParMap(inplane,volume,[selectedScans],[forceSave],[method],[noSaveFlag])
%
% Uses point sampling and nearest neighbor interpolation to map
% parameter map from inplane view to volume view.  Inplane and
% volume views must already be open. See ip2VolCoranal for details.
%
% forceSave: if entered as 1, will save the par map without prompting
% even if it already exists in the flat directory. Added this to
% help with automated xformation of many maps.
%
% noSaveFlag:  if 1, does not save out the interpolated map
%
% If you change this function make parallel changes in:
%    ip2volCorAnal, ip2volSpatialGradient, ip2volTSeries,
%    vol2flatCorAnal, vol2flatParMap, vol2flatTSeries
%
% rmk, 1/99
%
% Modifications:
% djh, 2/2001
% - Replaced globals with local variables
% - Data are no longer interpolated to the inplane size
% ras, 5/2004, allowed forceSave option to facilitate
% automated creation/xform of many param maps
% ras, 9/2005, a preference: converts over the map mode from
% inplane to volume as well. When using specific color maps or
% clip mode, it's nice to have it autoconvert, and easy enough
% to change back.
% sod 11/2005, option for linear interpolation. Defaults to nearest.
if notDefined('forceSave'),   forceSave  = 0;           end
if notDefined('method'),      method     = 'nearest';   end;
if notDefined('noSaveFlag'),  noSaveFlag = 0;           end;
fprintf('[%s]: using %s interpolation.\n',mfilename,method);

% Don't do this unless inplane is really an inplane and volume is really a volume
if ~strcmp(inplane.viewType,'Inplane')
    myErrorDlg('ip2volParMap can only be used to transform from inplane to volume/gray.');
end
if ~strcmp(volume.viewType,'Volume') &&~strcmp(volume.viewType,'Gray')
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
[inplane volume] = checkTypes(inplane, volume);

% Allocate space for the volume data arrays.
% If empty, initialize to cell array.
% If non-empty, grab it so that it can be updated.
%
if ~isempty(volume.map) && strcmp(inplane.mapName,volume.mapName)
    map = volume.map;
else
    map = cell(1,nScans);
end

% put up a mrvWaitbar, if consistent w/ VISTA 'verbose' preference
verbose = prefsVerboseCheck;
if verbose,
	waitHandle = mrvWaitbar(0,'Interpolating Parameter Map.  Please wait...');
end

% Tranform gray coords to inplane functional coords. Previously, the code
% to do this xform was duplicated in many functions, including this one.
% It is now a separate routine. The third argument when set to true returns
% the precise (non-integer) functional coords, which are interpolated
% below.
coordsXformed = ip2volXformCoords(volume, inplane, true);

% Loop through the scans and use interp3 to transform the values
% from the inplanes to the volume. For details, see ip2VolCorAnal
%
for curScan = selectedScans
    if verbose, mrvWaitbar((curScan-1)/nScans);  end

    % rsFactor is assumed to be the same in all scans, so we do not need
    % this step. (see upSampleFactor)
    %     rsFactor = upSampleFactor(inplane,curScan);
    %     if length(rsFactor)==1
    %         coordsXformed(1:2,:)=coordsXformedTmp(1:2,:)/rsFactor;
    %     else
    %         coordsXformed(1,:)=coordsXformedTmp(1,:)/rsFactor(1);
    %         coordsXformed(2,:)=coordsXformedTmp(2,:)/rsFactor(2);
    %     end
    if ~isempty(inplane.map{curScan})
        mapInplane = inplane.map{curScan}(:,:,:);
        mapInterpVol = interp3(mapInplane,...
            coordsXformed(2,:),...
            coordsXformed(1,:),...
            coordsXformed(3,:),...
            method);
        map{curScan} = reshape(mapInterpVol,dataSize(volume));
        clear tmp mapInplane mapInterpVol
    end
end

if verbose, close(waitHandle); end

volume = setParameterMap(volume, map, inplane.mapName, inplane.mapUnits);

% Set the fields in volume
%
if checkfields(inplane,'ui','mapMode') && checkfields(volume,'ui','mapMode')
    volume.ui.mapMode = inplane.ui.mapMode;
end

% Save to file
if ~noSaveFlag
    saveParameterMap(volume,[],forceSave,1);
end

return
