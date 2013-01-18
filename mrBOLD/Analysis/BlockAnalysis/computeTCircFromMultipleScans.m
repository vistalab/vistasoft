function tc=computeTCircFromMultipleScans(view,scanList)
% tc=computeTCircFromMultipleScans(view,scanList)
% PURPOSE: Computes the tCirc statistic from the amp and ph data
%           in a given set of scans. You need quite a few scans per
%           condition (here enforced as 4)
% AUTHOR: ARW wade@ski.org 020705
% $date$
mrGlobals

if (~exist('scanList','var') | isempty(scanList)), scanList = selectScans(view); end

checkScans(view,scanList);

nScans=length(scanList);
% Each scan gives us an amp and a ph. Combining these, we get a complex
% vector. So if we have 4 scans, we get 4 vectors per voxel.
% I don't really see why we can't just treat the ph and amp as 
% independent variables (like the real and imaginary parts). But for now,
% let's do it Johnathan's way and break that vector into re and im. Then
% compute the tcirc on those two "independent" numbers. Except that, of
% course, they're not independent...

thisAmp=cell2mat(shiftdim(view.amp(scanList),-2));
thisPh=cell2mat(shiftdim(view.ph(scanList),-2));

thisComp=thisAmp.*exp(sqrt(-1)*thisPh);
meanComp=mean(thisComp,4);
stdComp=std(thisComp,[],4);
tc=abs(meanComp)./stdComp;
