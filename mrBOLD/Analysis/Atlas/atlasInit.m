function atlasView = atlasInit(view,atlasName,nAtlases,newAtlasNum,atlasDim)
%
%   atlasView = atlasInit(view,atlasName,nAtlases,newAtlasNum,atlasDim)
%
% Author:
% Purpose:
%    We should use initHiddenFlat for this routine. But that function insists
% on recomputing the coords, and the paths to the flat mat are hard-coded
% and not machine independent, so it often breaks.

atlasView.name = atlasName;
atlasView.viewType = 'Flat';
atlasView.subdir = view.subdir;
atlasView.map = [];
atlasView.mapName = '';
atlasView.curDataType = newAtlasNum;
atlasView.coords = view.coords;
atlasView.grayCoords = view.grayCoords;
atlasView.leftPath = view.leftPath;
atlasView.rightPath = view.rightPath;
atlasView.co = cell(1, nAtlases);
atlasView.amp = cell(1, nAtlases);
atlasView.ph = cell(1, nAtlases);
atlasView.ui.imSize = view.ui.imSize;

% Fill up the co amp and ph with NaNs until the atlas is created.
for(ii=1:nAtlases)
    atlasView.co{ii} = repmat(NaN, atlasDim);
    atlasView.amp{ii} = repmat(NaN, atlasDim);
    atlasView.ph{ii} = repmat(NaN, atlasDim);
end

% In this model, there could be an existing atlas for the other hemisphere.
atlasView = loadCorAnal(atlasView);

return;
