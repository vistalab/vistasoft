function [img, mmPerVox] = dtiWarpMapToSubject(snParams, bb, mapFileName) 
%
% [img, mmPerVox] = dtiWarpMapToSubject(snParams, bb, mapFileName)
%
% HISTORY:
%  2005.01.28 RFD wrote it.

interpMethod = 1;
gui = 1;
V = spm_vol(mapFileName);
mmPerVox = spm_imatrix(snParams.sn.VF.mat); mmPerVox = mmPerVox(7:9);

x   = (bb(1,1):mmPerVox(1):bb(2,1));
y   = (bb(1,2):mmPerVox(2):bb(2,2));
z   = (bb(1,3):mmPerVox(3):bb(2,3));
img = zeros([size(x,2) size(y,2) size(z,2)]);
if(gui) h = mrvWaitbar(0,'Warping map to current brain...');
else h = 0; end
defSize = size(snParams.deformX);
for(ii=1:length(z))
    [X,Y,Z] = ndgrid(x, y, z(ii));
    sc =  [X(:) Y(:) Z(:) ones(size(X(:)))]';
    % Convert the source coords to the coordinate frame of the image
    % that was normalized (eg. this subject's T1).
    sc = round(inv(snParams.sn.VF.mat)*sc);
    %sc = round(inv(V.mat)*sc);
    scInd = sub2ind(defSize, sc(1,:), sc(2,:), sc(3,:));
    tc = double([snParams.deformX(scInd); snParams.deformY(scInd); snParams.deformZ(scInd)]);
    % Now convert the deformed coordinates to the coordinate frame of
    % the normalized image that we are loading in.
    tc = inv(V.mat)*[tc;ones(size(tc(1,:)))];
    img(:,:,ii) = reshape(spm_sample_vol(V, tc(1,:), tc(2,:), tc(3,:), interpMethod),size(img(:,:,1)));
    mrvWaitbar((ii)/length(z),h);
end
if(h) close(h); end
return;