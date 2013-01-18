function eigVal = dtiGetUniqueEigValsFromFibers(dt, fg)
% Read eigenvalues from fiber locations - one per voxel
%
%   eigVal = dtiGetUniqueEigValsFromFibers(dt, fg)
%
% This routine finds the voxels on a path - each voxel is counted uniquely.
% Then the routine returns only the eigenvalues once for each voxel.
%
% HISTORY:
% 2008.02.11 AJS & RFD: wrote it.
% Commented by BW - hopefully they are right.


% Find the unique coordinates by getting all of the coordinates for all of
% the fibers
coords = horzcat(fg.fibers{:})';

% Then round and unique them
coords = unique(round(mrAnatXformCoords(inv(dt.xformToAcpc),coords)),'rows');

% Now go make the indices
inds = sub2ind(size(dt.dt6(:,:,:,1)),coords(:,1),coords(:,2),coords(:,3));

%
vecDt6 = zeros(size(coords,1),6);

% Written for six directions, I guess
for ii=1:6
    temp = dt.dt6(:,:,:,ii);
    vecDt6(:,ii) = temp(inds);
end

[eigVec, eigVal] = dtiEig(vecDt6);

return;