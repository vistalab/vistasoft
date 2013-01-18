function img = mrCheckAlignVol(rot,trans,scaleFac,inpSize,inpZ,volume,sagSize,numSlices,obwin)
%
%  mrCheckAlignVol
%
%	 mrCheckAlignVol(rot,trans,scaleFac,inpSize,inpZ,volume,sagSize,numSlices,obwin);
%
%	Extracts a plane coresponding to queried for anatomical slice.
%

global volcmap volslimin1 volslimax1

if ~exist('obwin')
  obwin=4;
end

% Make a sampling grid

[xs,ys] = meshgrid([1:inpSize(2)],[1:inpSize(1)]);
xs = reshape(xs,1,prod(inpSize));
ys = reshape(ys,1,prod(inpSize));
zs = ones(1,prod(inpSize))*inpZ;
samp = [xs;ys;zs]';

%Rotate the grid

nusamp = (rot*(samp'./(ones(prod(inpSize),1)*(scaleFac(1,:)))'))'+(trans'*ones(1,length(samp)))';

%Convert back from millimeters

nusamp = nusamp.*(ones(prod(inpSize),1)*scaleFac(2,:));

figure(obwin); 
colormap(volcmap);

%Extract sampled image from volume.

img = mrExtractImgVol(volume,sagSize,numSlices,nusamp);
%img =
%
% reshape(fliplr(reshape(img,inpSize(1),inpSize(2))),1,prod(inpSize));
myShowImageVol(img,inpSize,max(img)*get(volslimin1,'value'),max(img)*get(volslimax1,'value'));





