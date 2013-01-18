function samp = mrExtractSagVol(sagSize,curSag);
%
%  mrExtractSagVol
%
%      samp = mrExtractSagVol(sagSize,curSag);
%
%	Generates a sampling matrix for sagittal anatomies
%	Not normally used, because quick hack can sample volume faster
%	for sagittals without going through mrExtractImgVol


[xs,ys] = meshgrid([1:sagSize(2)],[1:sagSize(1)]);
xs = reshape(xs,1,prod(sagSize));
ys = reshape(ys,1,prod(sagSize));
zs = ones(1,prod(sagSize))*curSag;
samp = [xs;ys;zs]';
