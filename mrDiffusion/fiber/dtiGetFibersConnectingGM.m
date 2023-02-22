function fgOut=dtiGetFibersConnectingGM(fg, dt, minDist, showFig)
%Select fibers with both endpoints located near grey matter.
%
%  fg=dtiFibersConnectingGM(fg, dt, [minDist=1.74])
%
% Returns a fibers structure which is a subset of fibers from the original
% fiber group, keeping only the fibers whose both endpoints terminate near
% grey matter or the most inferior axial plane (the latter to trap
% cortico-spinal fibers). Relies on spm to perform tissue segmentation of b0.
% Grey matter mask is rather generous: anything with probability(gm)>0. 
%
% Input parameters:
% minDist  - maximum distance from a fiber endpoint to Gm mask.
% showFig  - 'true', will show Gm mask; 'false', will save the mask.
%
% HISTORY:
% 07/31/2009 ER wrote it

if ~exist('showFig', 'var') || isempty(showFig)
showFig=false; 
end

if ~exist('minDist','var') || isempty(minDist)
    minDist=1.74;
end

[wm, gm, csf] = mrAnatSpmSegment(dt.b0, dt.xformToAcpc, 'mniepi'); gm=gm>=127;

% Only fibers whose both endpoints are within the gray matter (roi prepared) will be considered.
[x1,y1,z1] = ind2sub(size(gm), find(gm));

%fill up the most inferior nonzero slice & below with "gray matter" voxels -- to make
%sure corticospinal fibers will not be eliminated when retaining only
%"gray matter connecting" voxels.
gm_withcst=gm; 
gm_withcst(:, :, min(z1))=1;


[x1_withcst,y1_withcst,z1_withcst] = ind2sub(size(gm_withcst), find(gm_withcst));
roi4cst= dtiNewRoi('mrAnatSpmSegment_gm');
roi4cst.coords = mrAnatXformCoords(dt.xformToAcpc, [x1_withcst,y1_withcst,z1_withcst]);


[fgOut] = dtiIntersectFibersWithRoi([], {'and', 'both_endpoints'}, minDist, roi4cst, fg);

if showFig
    showMontage(gm_withcst); 
else
    imwrite(makeMontage(gm_withcst), fullfile(fileparts(dt.dataFile), 'bin', 'gmMask.png')); 
end
