function [nfc,nfcG] = nfgGetNormalizedFiberVolume(vID, goldID)
%Get fiber volume of each bundle normalized across the entire volume
%
%   [nfc] = nfgGetNormalizeFiberCount(vID, goldID)
%
%   vID is a cell array with each cell containing the bundle id of the test
%   projectome, nfc is a NCxNID matrix where NC is the number of cells in
%   vID and NID is the maxID in goldID.  The fiber counts in the nfg matrix
%   are normalzed by the number of fibers in the goldID bundle that is the
%   smallest gold ID where each of the test projectomes in vID had at least
%   one fiber in the bundle
%   
%
% NOTES: 



nfcG = hist(goldID,1:max(goldID));
nfc = zeros(length(vID),max(goldID));
for pp=1:length(vID)
    %nfc(pp,:) = sum(vID==bb);
    nfc(pp,:) = hist(vID{pp},1:max(goldID));
end

% Now multiply the fiber counts
    % Just normalize histograms
    nfc = nfc ./ repmat(sum(nfc,2),1,size(nfc,2));
    nfcG = nfcG ./ sum(nfcG);
return;


function [arcL] = arclength(fc)
arcL = sum(sqrt(sum((fc(:,2:end) - fc(:,1:end-1)).^2,1)));
return;