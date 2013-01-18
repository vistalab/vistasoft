function [coords, data] = dtiRoiGrow2d(data, xformToAcpc, seedAcpc, ax, tol, thick)
%
% [selectedCoords, data] = dtiRoiGrow2d(data, xformToAcpc, seedAcpc, ax, tol, [thick=1])
%
% data is either an image volume (scalar or dt6) or the data struct
% returned after calling this function once (useful if you want to iterate
% with the same image volume, just chaning the tolerance).
%
% seedAcpc: the seed point, in ac-pc coords
%
% ax: the axis to grow in (1,2 or 3). E.g., ax=1 will grow in the slice
% X=seedAcpc(1), ax=2 will grow in Y=seedAcpc(2), and ax=3 in
% Z=seedAcpc(3).
%
% tol: the tolerance (between 0 and 1, with lower values including fewer
% voxels).
%
% thick: the thickness of the resulting coordinates. The algorithm grows in
% a single slice. thick > 1 will replicate the selected coords in adjacent
% slices for you.
%
% E.g.:
% dt = dtiLoadDt6('dti06trilinrt/dt6');
% seedAcpc = [-36 -28 26];
% ax = 3;
% tol = .20;
% [coords, data] = dtiRoiGrow2d(dt.dt6, dt.xformToAcpc, seedAcpc, ax, tol);
% % Show the delta image with the selected coords overlaid
% figure; image(data.x(:), data.y(:), data.img); axis equal tight xy;
% hold on; plot(coords(:,1),coords(:,2),'k.'); hold off;
%
% % do it again with stricter tol and passing the pre-processed data:
% coords = dtiRoiGrow2d(data, dt.xformToAcpc, seedAcpc, ax, 0.10);
% figure; image(data.x(:), data.y(:), data.img); axis equal tight xy;
% hold on; plot(coords(:,1),coords(:,2),'k.'); hold off;
%
% HISTORY
% 2009.08.26 RFD: pulled code from dtiFiberUI so that we can easily scrip it.
%

if(~exist('thick','var')||isempty(thick))
    thick = 1;
end

if(~isstruct(data))
    if(ndims(data)==3)
        [img,x,y,z] = dtiGetSlice(xformToAcpc, data, ax, seedAcpc(ax), [], 'n');
        if(ax==2), yseed = find(x(:,1)>seedAcpc(1)-.5&x(:,1)<=seedAcpc(1)+.5);
        else yseed = find(y(:,1)>seedAcpc(2)-.5&y(:,1)<=seedAcpc(2)+.5); end
        if(ax==3), xseed = find(x(1,:)>seedAcpc(1)-.5&x(1,:)<=seedAcpc(1)+.5);
        else xseed = find(z(1,:)>seedAcpc(3)-.5&z(1,:)<=seedAcpc(3)+.5); end
    elseif(ndims(data)==4)
        % Then it's a dt6 (tensor). We'll create a map of the angle between the
        % seed point PDD and each image voxel PDD.
        [dt6,x,y,z] = dtiGetSlice(xformToAcpc, data, ax, seedAcpc(ax), [], 'n');
        if(ax==2), yseed = find(x(:,1)>seedAcpc(1)-.5&x(:,1)<=seedAcpc(1)+.5);
        else yseed = find(y(:,1)>seedAcpc(2)-.5&y(:,1)<=seedAcpc(2)+.5); end
        if(ax==3), xseed = find(x(1,:)>seedAcpc(1)-.5&x(1,:)<=seedAcpc(1)+.5);
        else xseed = find(z(1,:)>seedAcpc(3)-.5&z(1,:)<=seedAcpc(3)+.5); end
        [eigVec,eigVal] = dtiEig(dt6);
        seedPdd = squeeze(eigVec(yseed,xseed,:,1));
        % dot(eigVec(1,:),[1 0 0]) = eigVec(1,1) and dot(eigVec(1,:),[0 1 0]) = eigVec(1,2)
        img = eigVec(:,:,1,1).*seedPdd(1)+eigVec(:,:,2,1).*seedPdd(2)+eigVec(:,:,3,1).*seedPdd(3);
        img(img>1) = 1; img(img<-1) = -1;
        img = acos(img);
        % Reflect about pi/2 for angles > pi/2 (diffusion is symmetric along the eigenvector axis)
        img(img>pi/2) = pi/2-(img(img>pi/2)-pi/2);
        img = img./(pi/2);
        % FA an MD should matter too, since we usually don't want to grow
        % into regions with very different anisotropy from our seed. But-
        % should it get equal weighting to our angle measure? Maybe make it a
        % parameter?
        [fa,md] = dtiComputeFA(eigVal);
        maxMd = md(yseed,xseed)*3;
        md(md>maxMd) = maxMd;
        md = md./maxMd;
        %img = 0.5*img + 0.5*abs(fa-fa(yseed,xseed));
        img = cat(3, img, abs(fa-fa(yseed,xseed)), abs(md-md(yseed,xseed)));
        %figure;imagesc(img);axis image xy; colormap gray
    end
    clear data;
    data.img = img;
    data.x = x;
    data.y = y;
    data.z = z;
    data.xseed = xseed;
    data.yseed = yseed;
end

binImg = magicwand1(data.img, data.yseed, data.xseed, tol);
ind = find(binImg);
coords = [data.x(ind), data.y(ind), data.z(ind)];
for(ii=[1:thick-1,-1:-1:-(thick-1)])
	newLayer = coords; 
    newLayer(:,ax) = newLayer(:,ax)+ii;
    coords = [coords; newLayer];
end
coords = unique(coords, 'rows');
return;
