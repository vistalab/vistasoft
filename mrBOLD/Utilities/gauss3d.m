function outArray=gauss3d(hSize,sigma)
% outArray=gauss3d(hSize,sigma)
% Generate a 3D gaussian 
% If hSize is a scalar, assume a cubic array
% Otherwise, hSize must be 3x1 vector
% Same for sigma
% ARW 042904
% Example: g=gauss3d([7 7 7],[3 3 3]);
% See also fspecial
% NOTE: Gaussians returned have a peak value of '1'

if (~exist('sigma','var'));
    sigma=3;
end
if (~exist('hSize','var'));
    hSize=7;
end

sigma=sigma(:);
hSize=hSize(:);

if ((length(hSize)~=3) & (length(hSize)~=1))
    error('hSize must be scalar or 3x1');
end
if ((length(sigma)~=3) & (length(sigma)~=1))
    error('sigma must be scalar or 3x1');
end

if (length(hSize)==1)
    hSize=ones(3,1)*hSize;
end
if (length(sigma)==1)
    sigma=ones(3,1)*sigma;
end

sigma=round(sigma);
hSize=round(hSize);

if(find(sigma<1))
    error('sigma cannot be less than 1');
end
if(find(hSize<1))
    error('hSize cannot be less than 1');
end

yRange=(-fix(hSize(1)/2)):(fix(hSize(1)/2));
xRange=(-fix(hSize(2)/2)):(fix(hSize(2)/2));
zRange=(-fix(hSize(3)/2)):(fix(hSize(3)/2));

[yg,xg,zg]=ndgrid(yRange,xRange,zRange);
gaussY=exp(-(yg.^2)/(2*sigma(1).^2));
gaussX=exp(-(xg.^2)/(2*sigma(2).^2));
gaussZ=exp(-(zg.^2)/(2*sigma(3).^2));

outArray=gaussY.*gaussX.*gaussZ;


