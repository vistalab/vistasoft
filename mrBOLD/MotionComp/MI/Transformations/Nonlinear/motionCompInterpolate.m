function img = motionCompInterpolate(img,ux,uy,uz,order)

if ~exist('order','var') || isempty(order)
    order = 7;
end

bSplineParams = [repmat(order,[1 3]) zeros(1,3)];
bsplineCoefs = spm_bsplinc(img, bSplineParams);

dims = size(img);

[x,y,z] = ndgrid(1:dims(1),1:dims(2),1:dims(3));
img = spm_bsplins(bsplineCoefs,x - ux,y - uy,z - uz,bSplineParams);

img(isnan(img)) = 0;
