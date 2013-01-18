function curCalc = mrExtractCalcVol(rot,trans,scaleFac,inpSize,inpZ,...
			  	sagSize, calc, dataRange);
%
% MrExtractCalcVol
%
%    curCalc = mrExtractCalcVol(rot,trans,scaleFac,inpSize,inpZ ...
%			  	sagSize, calc,dataRange);
%
%	Samples calcarine data of inplane antomical plane specified by inpZ.
%

if ( isempty(rot) | isempty(trans) | isempty(scaleFac) )
	error('You have to compute a rotation before you can extract calcarine');
end

[xs,ys] = meshgrid([1:inpSize(2)],[1:inpSize(1)]);
xs = reshape(xs,1,prod(inpSize));
ys = reshape(ys,1,prod(inpSize));
zs = ones(1,prod(inpSize))*inpZ;
samp = [xs;ys;zs]';

%Rotate the grid

nusamp = (rot*(samp'./(ones(prod(inpSize),1)*(scaleFac(1,:)))'))'+(trans'*ones(1,length(samp)))';

%Convert back from millimeters

nusamp = nusamp.*(ones(prod(inpSize),1)*scaleFac(2,:));

%Extract sampled image from calcarine
figure;
curCalc = mrExtractImgVol(calc,sagSize,(dataRange(2)-dataRange(1))+1,nusamp,dataRange);
imagesc(reshape(curCalc,inpSize(1),inpSize(2)))
axis image

