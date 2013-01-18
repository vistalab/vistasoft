function [fibersSel, fibersNonSel, iBundleSel] = nfgMatchProjectome(fgG,g_bundleID,fgProj,dThresh)
%Match fibers to gold standard fibers that are grouped into bundles
%
%   [fibersSel, fibersNonSel, iBundleSel] =
%   nfgMatchProjectome(fgG,g_bundleID,fgProj,dThresh)
%
%
%
% NOTES: 


% Group endpoints for each bundle
% Make sure fibers have the length in the columns
fgG.fibers = fgG.fibers(:)';
fiberLen = cellfun('size',fgG.fibers,2);
fc = horzcat(fgG.fibers{:});
eID = cumsum(fiberLen);
sID = [1 1+eID(1:end-1)];
gs = fc(:,sID);
ge = fc(:,eID);

fgProj.fibers = fgProj.fibers(:)';
fiberLen = cellfun('size',fgProj.fibers,2);
fc = horzcat(fgProj.fibers{:});
eID = cumsum(fiberLen);
sID = [1 1+eID(1:end-1)];
ps = fc(:,sID);
pe = fc(:,eID);

% Distances between all endpoint pairs
dss = point_dist(gs,ps);
dse = point_dist(gs,pe);
des = point_dist(ge,ps);
dee = point_dist(ge,pe);
% Get max distance between endpoints for the situation where the pathways
% are oriented the same as the gold standard or switched
dSame = max(dss,dee);
dSwitch = max(dse,des);
% For each projectome pathway get the minimum distance bundle
[dSameMin, iSameMin] = min(dSame,[],2);
[dSwitchMin, iSwitchMin] = min(dSwitch,[],2);
dSel = dSameMin;
iSel = iSameMin;
iSel(dSameMin>dSwitchMin) = iSwitchMin(dSameMin>dSwitchMin);
dSel(dSameMin>dSwitchMin) = dSwitchMin(dSameMin>dSwitchMin);
% Convert gold threads into bundles
iBundleSel = g_bundleID(iSel);
iBundleSel(dSel>=dThresh) = 0;
fibersSel = fgProj.fibers(iBundleSel>0);
fibersNonSel = fgProj.fibers(iBundleSel==0);
iBundleSel = iBundleSel(iBundleSel>0);

return;


function [d] = point_dist(pts1,pts2)
[px1,px2] = meshgrid(pts1(1,:),pts2(1,:));
[py1,py2] = meshgrid(pts1(2,:),pts2(2,:));
[pz1,pz2] = meshgrid(pts1(3,:),pts2(3,:));
d = sqrt((px1-px2).^2 + (py1-py2).^2 + (pz1-pz2).^2);
return;