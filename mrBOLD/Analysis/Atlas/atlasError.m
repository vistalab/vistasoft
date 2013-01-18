function vw = atlasError(vw)
%
% vw = atlasErrorMap(vw)
% 
% Author:
% Purpose:
%   2003.01.14 RFD (bob@white.stanford.edu): wrote it.

ringWedgeScans = readRingWedgeScans;
wedgeScanNum =ringWedgeScans(2);
ringScanNum = ringWedgeScans(1);
atlasView = getAtlasView;
if(isempty(atlasView)), myErrorDlg('Open a FLAT window in Atlas view.'); end
curDataType = dtGetCurNum(vw);
curSlice = viewGet(vw, 'Current Slice');

% Create a map for every scan num.  This is the parameter map field.
for(ii=1:numScans(vw)),  vw.map{ii} = []; end

d = vw.ph{wedgeScanNum}(:,:,curSlice);
a = atlasView.ph{wedgeScanNum}(:,:,curSlice);
vw.map{wedgeScanNum}(:,:,curSlice) = abs(exp(sqrt(-1)*d) - exp(sqrt(-1)*a));

d = vw.ph{ringScanNum}(:,:,curSlice);
a = atlasView.ph{ringScanNum}(:,:,curSlice);
vw.map{ringScanNum}(:,:,curSlice) = abs(exp(sqrt(-1)*d) - exp(sqrt(-1)*a));

vw.ui.mapMode.clipMode = [0,pi];

vw.map{wedgeScanNum}(isnan(vw.map{wedgeScanNum})) = -0.01;
vw.map{ringScanNum}(isnan(vw.map{ringScanNum})) = -0.01;

vw.ui.mapMode = setColormap(vw.ui.mapMode,'hotCmap');

return;

% figure; 
% plot(d(:),a(:),'.')

