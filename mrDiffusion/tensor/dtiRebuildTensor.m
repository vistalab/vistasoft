function tensor = dtiRebuildTensor(eigVec, eigVal)

% tensor = dtiRebuildTensor(eigVec, eigVal)
% 
% Rebuilds the tensor elements from eigVec and eigVal arrays (as from
% dtiLoadTensor), given in XxYxZx3x3xN and XxYxZx3xN format, repectively,
% where N is the number of subjects.
% The unique 6 values are returned as a XxYxZx6xN array.
% The order is [Dxx, Dyy, Dzz, Dxy, Dxz, Dyz].
%
% HISTORY:
% 2003.11.26 RFD (bobd@stanford.edu) Wrote it.
% 2003.12.04 RFD: vectorized for ~40X speed increase.
% 2004.02.16 ASH (armins@stanford.edu): added extra dimension for subjects
% 2004.03.22 ASH: fixed for backwards compatibility

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

return;
