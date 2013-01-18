function [nfc,nfcG] = nfgGetNormalizeFiberCount(vID, goldID)
%Get fiber counts in each bundle as a factor of the smallest gold bundle
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

bNormalizeToBaseBundle = 0;

nfcG = hist(goldID,1:max(goldID));
nfc = zeros(length(vID),max(goldID));
for pp=1:length(vID)
    %nfc(pp,:) = sum(vID==bb);
    nfc(pp,:) = hist(vID{pp},1:max(goldID));
end
if bNormalizeToBaseBundle
    % Find the bundle that has at least one fiber in each projection group
    nfcMask = all(nfc>0,1);
    nfcTest = nfcMask .* nfcG;
    nfcTest(nfcTest==0) = max(goldID)+1;
    % Find the gold bundle with minimum size that has a fiber in each
    % projectome
    [mval, idBase] = min(nfcTest);
    % Get count base to normalize each fiber group by
    countBase = repmat(nfc(:,idBase),1,max(goldID));
    % Normalize for each fiber group
    nfc = nfc ./ countBase;
    % Normalize the gold group
    nfcG = nfcG / nfcG(idBase);
else
    % Just normalize histograms
    nfc = nfc ./ repmat(sum(nfc,2),1,size(nfc,2));
    nfcG = nfcG ./ sum(nfcG);
end
return;