function [permuteMatrix, nNonRepeats, nUniqueDirs, nUniqueMeasurements] = dtiBootGetPermMatrix(bvecs, bvals)
%
% [permuteMatrix, nNonRepeats, nUniqueDirs, nUniqueMeasurements] = dtiBootGetPermMatrix(bvecs, bvals)
%
%
% HISTORY:
% 2007.06.07 RFD wrote it

n = min(size(bvals,2),size(bvecs,2));
bv = [bvecs(:,1:n).*repmat(bvals(:,1:n),[3 1])];
nMeasurements = size(bv,2);
permuteMatrix = cell(nMeasurements,1);
for(ii=1:nMeasurements)
    dist1 = sqrt((bv(1,:)-bv(1,ii)).^2+(bv(2,:)-bv(2,ii)).^2+(bv(3,:)-bv(3,ii)).^2);
    dist2 = sqrt((bv(1,:)+bv(1,ii)).^2+(bv(2,:)+bv(2,ii)).^2+(bv(3,:)+bv(3,ii)).^2);
    permuteMatrix{ii} = unique([find(dist1<1e-3) find(dist2<1e-3)]);
end
numPerms = cellfun('length',permuteMatrix);
nNonRepeats = sum(numPerms==1);
m = zeros(nMeasurements,max(numPerms)); 
for(ii=1:nMeasurements) 
    m(ii,1:length(permuteMatrix{ii})) = permuteMatrix{ii}; 
end
nUniqueMeasurements = size(unique(m,'rows'),1);
if(any(bvals<max(bvals)*0.01))
    nUniqueDirs = nUniqueMeasurements-1;
else
    nUniqueDirs = nUniqueMeasurements;
end

return