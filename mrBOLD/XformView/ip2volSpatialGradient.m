function volume= ip2volSpatialGradient(inplane,volume)
%
% volume= ip2volSpatialGradient(inplane,volume)
%
% Uses point sampling and nearest neighbor interpolation to map
% spatial gradient from inplane view to volume view.  Inplane and
% volume views must already be open. See ip2VolCoranal for details.
%
% If you change this function make parallel changes in:
%    ip2volCorAnal, ip2volParMap, ip2volTSeries, 
%    vol2flatCorAnal, vol2flatParMap, vol2flatTSeries
%
% djh, 2/2001

mrGlobals;

% Don't do this unless inplane is really an inplane and volume is really a volume
if ~strcmp(viewGet(inplane,'viewType'),'Inplane')
    myErrorDlg('ip2volParMap can only be used to transform from inplane to volume/gray.');
end
if ~strcmp(viewGet(volume,'View Type'),'Volume') && ~strcmp(viewGet(volume,'viewType'),'Gray')
    myErrorDlg('ip2volParMap can only be used to transform from inplane to volume/gray.');
end

% Check that both inplane & volume are properly initialized
if isempty(inplane)
  myErrorDlg('Inplane view must be open.  Use "Open Inplane Window" from the Window menu.');
end
if isempty(volume)
  myErrorDlg('Gray/volume view must be open.  Use "Open Gray/Volume Window" from the Window menu.');
end
if isempty(inplane.spatialGrad)
  myErrorDlg('Inplane spatial gradient must be set. Use File/Parameter Map/Load Spatial Gradient.');
end

% Check that dataType is the same for both views. If not, doesn't make sense to do the xform.
% because for example the two dataTypes may have a different number of scans.
[inplane, volume] = checkTypes(inplane, volume);

% Compute the transformed coordinates (i.e., where does each gray node fall in the inplanes).
% The logic here is copied from ip2volCorAnal.
nVoxels = size(volume.coords,2);
coords = [volume.coords; ones(1,nVoxels)];
vol2InplaneXform = inv(mrSESSION.alignment);
vol2InplaneXform = vol2InplaneXform(1:3,:);
coordsXformed = vol2InplaneXform*coords;
n = viewGet(inplane,'Size') ./ size(inplane.spatialGrad);
if n(1) ~= n(2)
    disp('Warning! upSampling is different in x and y');
else
    upsamplefactor = n(1);
end
coordsXformed(1:2,:)=coordsXformed(1:2,:)/upsamplefactor;

% Map the spatial gradient
spatialGradInterpVol = interp3(inplane.spatialGrad,...
    coordsXformed(2,:),...
    coordsXformed(1,:),...
    coordsXformed(3,:),...
    'nearest');
spatialGrad = reshape(spatialGradInterpVol,dataSize(volume));

% Set spatialGrad field
volume.spatialGrad = spatialGrad;

% Save file
pathStr=fullfile(viewDir(volume),'spatialGradMap');
save(pathStr,'spatialGrad');

