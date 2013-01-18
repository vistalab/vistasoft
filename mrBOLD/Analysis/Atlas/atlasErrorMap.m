function view = atlasErrorMap(view)
%
% view = atlasErrorMap(view)
% 
% HISTORY:
%   2003.01.14 RFD (bob@white.stanford.edu): wrote it.

ringWedgeScans = readRingWedgeScans;
atlasView = getAtlasView;
if(isempty(atlasView)), myErrorDlg('Open an FLAT window in Atlas view.'); end

% Create a map for every scan num.  This is the parameter map field.
for(ii=1:numScans(view)),  view.map{ii} = []; end

for(slice=1:2)
    d = view.ph{wedgeScanNum}(:,:,slice);
    a = atlasView.ph{wedgeScanNum}(:,:,slice);
    view.map{wedgeScanNum}(:,:,slice) = abs(exp(sqrt(-1)*d) - exp(sqrt(-1)*a));
    
    d = view.ph{ringScanNum}(:,:,slice);
    a = atlasView.ph{ringScanNum}(:,:,slice);
    view.map{ringScanNum}(:,:,slice) = abs(exp(sqrt(-1)*d) - exp(sqrt(-1)*a));
    
    view.ui.mapMode.clipMode = [0,pi];
end

view.map{wedgeScanNum}(isnan(view.map{wedgeScanNum})) = -0.01;
view.map{ringScanNum}(isnan(view.map{ringScanNum})) = -0.01;

view.ui.mapMode = setColormap(view.ui.mapMode,'hotCmap');

return;
