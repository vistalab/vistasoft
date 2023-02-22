function volView = flat2volMap(flatView, volView, scans)
% 
% volMap = flat2volMap(flatView, volView, scans)
%
% Creates a gray-volume parameter map from a flat-view map by looking up
% the corresponding coords and mapping each flat-map value to the
% corresponding gray voxel in FLAT.grayCoords. Can specify optional list of
% scans to operate upon. Default is to convert all scans.%   
% volView must be the VOLUME structure.
% flatView must be the FLAT structure.
%
% Ress, 04/05

mrGlobals

if ~exist('volView', 'var')
  if isempty(selectedVOLUME)
    if isempty(VOLUME{1})
      Alert('Open and select a gray VOLUME window!');
      return
    else
      selectedVOLUME = 1;
    end
  end
  volView = VOLUME{selectedVOLUME};
end
if ~strcmp(volView.viewType, 'Gray'), volView = switch2Gray(volView); end
if isempty(volView.anat), flatView = loadAnat(volView); end
vDims = size(volView.anat);
vInds = coords2Indices(volView.coords, vDims);

if ~exist('flatView', 'var')
  if isempty(selectedFLAT)
    if isempty(FLAT{1})
      Alert('Open and select a FLAT window!');
      return
    else
      selectedFLAT = 1;
    end
  end
  flatView = FLAT{selectedFLAT};
end
if isempty(flatView.anat), flatView = loadAnat(flatView); end
fDims = size(flatView.anat);
flatImSize = fDims(1:2);

nScans = length(flatView.map);
if ~exist('scans', 'var'), scans = 1:nScans; end
volMap = cell(1, nScans);
if nScans == 0, return, end

% Check that dataType is the same for both views. If not, doesn't make sense to do the xform.
% because for example the two dataTypes may have a different number of scans.
checkTypes(flatView, volView);

% First pass to convert flat hemisphere coordinates to indices:
waitHandle = mrvWaitbar(0, 'Preparing to transform parameter map...');
volIndices = cell(1, 2);
flatIndices = cell(1, 2);
for h = 1:2
  flatIndices{h} = coords2Indices(round(flatView.coords{h}), flatImSize);
  volIndices{h} = coords2Indices(flatView.grayCoords{h}, vDims);
end

mrvWaitbar(0, waitHandle, 'Transforming parameter map...')
for iS=1:nScans
  if any(iS == scans)
    vMap = repmat(NaN, vDims);
    for h = 1:2
      map = flatView.map{iS}(:, :, h);
      if ~isempty(map)
        vMap(volIndices{h}) = map(flatIndices{h});
      end
    end
    volMap{iS} = vMap(vInds);
  end
  mrvWaitbar(iS/nScans, waitHandle)
end
close(waitHandle);

if isfield(flatView, 'mapName')
  mapName = flatView.mapName;
else
  mapName='';
end
volView = setParameterMap(volView, volMap, mapName);
saveParameterMap(volView);
VOLUME{selectedVOLUME} = volView;

return
