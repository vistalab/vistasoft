function [teE, teW] = nfgCompareAllVolumeTrueError(fgG,g_bundleID,g_radius,fibersSel,iBundleSel,phantomDir)
%Compare volume of all fiber matches using trueError program.
%
%   [teE, teW] =
%   nfgCompareAllVolumeTrueError(fgG,g_bundleID,g_radius,fibersSel,iBundleS
%   el,phantomDir)
%
%
%
% NOTES: 


% if ieNotDefined('projName'); projName = 'projectome'; end

% XXX THE BELOW TEST MUST BECOME GENERIC
% First lets find the optimum radius for the trueError test using a
% particular bundle
disp('Searching for near optimal test diameter ...');
selID = 4;
sMask = zeros(size(iBundleSel));
gMask = zeros(size(g_bundleID));
for ss=selID
    sMask = sMask | iBundleSel==ss;
    gMask = gMask | g_bundleID==ss;
end
vRadiusTE = 0.01:0.005:0.03;
fgSS = dtiNewFiberGroup();
fgGS = dtiNewFiberGroup();
fgSS.fibers = fibersSel(sMask);
fgGS.fibers = fgG.fibers(gMask);
[imgE] = nfgCompareVolumeTrueError(fgGS, fgSS, g_radius(1), vRadiusTE, phantomDir);
[mIE, iIE] = min(imgE);
te_radius = vRadiusTE(iIE);
% te_radius = 0.014;
disp(['Found optimal diameter = ' num2str(te_radius*2) 'mm.']);

% Calculate arclengths of all bundles found in projectome and in gold
teE = zeros(1,max(g_bundleID));
teW = zeros(1,max(g_bundleID));
fgSS = dtiNewFiberGroup();
fgGS = dtiNewFiberGroup();
for bb=1:max(g_bundleID)
    disp(['Computing volume for bundle ' num2str(bb) ' ...']);
    fgSS.fibers = fibersSel(iBundleSel==bb);
    fgGS.fibers = fgG.fibers(g_bundleID==bb);
    if isempty(fgSS.fibers)
        if ~isempty(fgGS.fibers)
            teE(bb) = 100;
        end
    else
        [teE(bb), teW(bb)] = nfgCompareVolumeTrueError(fgGS, fgSS, g_radius(bb), te_radius, phantomDir);
    end
    
end

return;