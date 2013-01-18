function [logP,siglev] = FDRthresholding(siglev)
%
% Function to get logP value for FDR threshold (at a level of siglev) from a mrVista
% Volume/Gray parameter map.  It uses the currently selected VOLUME.
%
%   siglev should be entered in the format 0.05 (meaning a false discovery
%   rate of 5%)
%
%   [logP,siglev] = FDRthresholding([siglev=0.05])
%
%  written by amr and rfd a long time ago (~2008)
%
global selectedVOLUME
global VOLUME

volView = VOLUME{selectedVOLUME};

if notDefined('siglev'), siglev = 0.05; end

log10p = volView.map{volView.curScan};
log10p(log10p<=0) = 1;
p=10.^-log10p;
[nSig,indSig] = fdr(p,siglev,'general');
logP = -log10(max(p(indSig)));

return