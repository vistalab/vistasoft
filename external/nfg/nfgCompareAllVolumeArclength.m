function [fvol, fvolG, fvolNon] = nfgCompareAllVolumeArclength(fgG,g_bundleID,g_radius,vR,fibersSel,fibersNonSel,iBundleSel,bApplyHagmannWeight)
%Compare volume of all matching fiber groups using arclength.
%
%   [E, volPNonBundle, volG] =
%   nfgCompareAllVolumeArclength(fgG,g_bundleID,g_radius,vR,fibersSel,fiber
%   sNonSel,iBundleSel,phantomDir)
%
%
% NOTES: 


% Calculate arclengths of all bundles found in projectome and in gold
lengthPB = zeros(1,max(g_bundleID));
lengthGB = zeros(1,max(g_bundleID));
Wh = ones(1,max(g_bundleID));
for bb=1:max(g_bundleID)
    % Add up all the arc lengths for the projectome fibers in this bundle
    fibers = fibersSel(iBundleSel==bb);
    for ff=1:length(fibers)
        al = arclength(fibers{ff});
        lengthPB(bb) = lengthPB(bb) + al;
    end
    if length(fibers)>0
        Wh(bb) = lengthPB(bb) / length(fibers);
    end
    % Add up all the arc lengths for the gold fibers in this bundle
    fibers = fgG.fibers(g_bundleID==bb);
    for ff=1:length(fibers)
        al = arclength(fibers{ff});
        lengthGB(bb) = lengthGB(bb) + al;
    end
end
% Get arclengths of projectome fibers not in bundles
alNonBundle=0;
for ff=1:length(fibersNonSel)
    alNonBundle = alNonBundle + arclength(fibersNonSel{ff});
end
fvolNon = alNonBundle / (sum(lengthPB)+sum(alNonBundle));
fvol = lengthPB/sum(lengthPB);
fvolG = lengthGB/sum(lengthGB);
if bApplyHagmannWeight
    fvol = fvol .* Wh;
end
    
% % Calculate volume occupied by gold bundles
% volG = lengthGB * max(g_radius)^2 * pi;
% volP = lengthPB * pi;
% volPNonBundle = alNonBundle * pi;
% % Search for the best radius for the projectome
% E = zeros(length(vR),length(volP));
% for rr=1:length(vR)
%     E(rr,:) = volG - volP*vR(rr)^2;
% end
% percentE = sum(abs(E),2)/sum(volG)*100;
% [minE, minI] = min(percentE);
% % Return bundlewise error for only the radius with optimal estimate
% E = E(minI,:);

return;


function [arcL] = arclength(fc)
arcL = sum(sqrt(sum((fc(:,2:end) - fc(:,1:end-1)).^2,1)));
return;