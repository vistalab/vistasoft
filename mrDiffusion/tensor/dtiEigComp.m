function tensor = dtiEigComp(eigVec, eigVal)

% Recovers a DTI data array in dt6 format [Dxx, Dyy, Dzz, Dxy, Dxz, Dyz]
% from arrays of eigenvalues and eigenvectors .
%
% DT_ARRAY = dtiEigComp(eigVec, eigVal)
% 
% Input:
%   eigVec      XxYxZx3x3xn (or nx3x3xN) array of eigenvectors
%   eigVal      XxYxZx3xn (or nx3xN) array of eigenvalues
%
% Output:
%   DT_ARRAY    Data array of size XxYxZx6xN (or nx6xN), where X, Y, Z are the volume
%                   dimensions and N is the number of subjects.
%                   (n is the number of voxels).
%
% See also:     dtiEig.m
%
% WARNING: If using Pentium 4, eliminate NaN's from array before running
% (processor bug).

% HISTORY:
% 2003.11.26 RFD (bobd@stanford.edu) Wrote it as dtiRebuildTensor.m
% 2003.12.04 RFD: vectorized for ~40X speed increase
% 2004.02.16 ASH (armins@stanford.edu): added extra dimension for subjects
% 2004.03.22 ASH: fixed for backwards compatibility
% 2006.07.12 ASH: renamed as dtiEigComp.m and added indexed format

% Check inputs
if (ndims(eigVal)==2 || ndims(eigVal)==3),
    Ind = 1;    % eigVal in indexed nx3xN format
    eigVal = shiftdim(eigVal, -2);
    eigVec = shiftdim(eigVec, -2);
else
    Ind = 0;    % eigVal in XxYxZx3xN format
end
if (ndims(eigVal)<4 || ndims(eigVal)>5),
    error('Wrong input format');
end
if (size(eigVal,1) ~= size(eigVec,1) || size(eigVal,2) ~= size(eigVec,2) || ...
    size(eigVal,3) ~= size(eigVec,3) || size(eigVal,4) ~= size(eigVec,4) || ...
    size(eigVal,5) ~= size(eigVec,6) || ...
    size(eigVal,4) ~= 3 || size(eigVec,5) ~= 3),
    error('Wrong input format');
end

% Main
sz = size(eigVal);
if (length(sz)>4),
    N = sz(5);
    eigVal = shiftdim(shiftdim(shiftdim(eigVal, 4), -1), 2);
else
    N = 1;
end
tensor = zeros([sz(1:3), 6, N]);

% The following is a much faster implementation of the (more readable) code
% below. For large data sets, it's about 40 times faster.
tensor(:,:,:,1,:) = eigVec(:,:,:,1,1,:).*eigVal(:,:,:,1,1,:).*eigVec(:,:,:,1,1,:) ...
                + eigVec(:,:,:,1,2,:).*eigVal(:,:,:,2,1,:).*eigVec(:,:,:,1,2,:) ...
                + eigVec(:,:,:,1,3,:).*eigVal(:,:,:,3,1,:).*eigVec(:,:,:,1,3,:);
tensor(:,:,:,2,:) = eigVec(:,:,:,2,1,:).*eigVal(:,:,:,1,1,:).*eigVec(:,:,:,2,1,:) ...
                + eigVec(:,:,:,2,2,:).*eigVal(:,:,:,2,1,:).*eigVec(:,:,:,2,2,:) ...
                + eigVec(:,:,:,2,3,:).*eigVal(:,:,:,3,1,:).*eigVec(:,:,:,2,3,:);
tensor(:,:,:,3,:) = eigVec(:,:,:,3,1,:).*eigVal(:,:,:,1,1,:).*eigVec(:,:,:,3,1,:) ...
                + eigVec(:,:,:,3,2,:).*eigVal(:,:,:,2,1,:).*eigVec(:,:,:,3,2,:) ...
                + eigVec(:,:,:,3,3,:).*eigVal(:,:,:,3,1,:).*eigVec(:,:,:,3,3,:);
tensor(:,:,:,4,:) = eigVec(:,:,:,1,1,:).*eigVal(:,:,:,1,1,:).*eigVec(:,:,:,2,1,:) ...
                + eigVec(:,:,:,1,2,:).*eigVal(:,:,:,2,1,:).*eigVec(:,:,:,2,2,:) ...
                + eigVec(:,:,:,1,3,:).*eigVal(:,:,:,3,1,:).*eigVec(:,:,:,2,3,:);
tensor(:,:,:,5,:) = eigVec(:,:,:,1,1,:).*eigVal(:,:,:,1,1,:).*eigVec(:,:,:,3,1,:) ...
                + eigVec(:,:,:,1,2,:).*eigVal(:,:,:,2,1,:).*eigVec(:,:,:,3,2,:) ...
                + eigVec(:,:,:,1,3,:).*eigVal(:,:,:,3,1,:).*eigVec(:,:,:,3,3,:);
tensor(:,:,:,6,:) = eigVec(:,:,:,2,1,:).*eigVal(:,:,:,1,1,:).*eigVec(:,:,:,3,1,:) ...
                + eigVec(:,:,:,2,2,:).*eigVal(:,:,:,2,1,:).*eigVec(:,:,:,3,2,:) ...
                + eigVec(:,:,:,2,3,:).*eigVal(:,:,:,3,1,:).*eigVec(:,:,:,3,3,:);

% h = mrvWaitbar(0, 'Computing tensors...');
% for(x=1:sz(1))
%     for(y=1:sz(2))
%         for(z=1:sz(3))
%             vec = squeeze(eigVec(x,y,z,:,:));
%             val = diag(squeeze(eigVal(x,y,z,:)));
%             t = vec*val*vec';
%             % this is the order that Pajevic's interpolation code likes.
%             tensor(x,y,z,:) = [t(1,1), t(2,2), t(3,3), t(1,2), t(1,3), t(2,3)]; 
%         end
%     end
%     mrvWaitbar(x/sz(1),h);
% end
% close(h);

% Adjust output
if Ind,
    tensor = shiftdim(tensor, 2);
end
