function gauss = dtiGauss3(dims,sigma)
%
% gauss = dtiGauss3(dims,sigma)
%
% HISTORY:
% 2007.11.08 RFD: wrote it.

if(numel(sigma==1))
    sigma = [sigma sigma sigma];
end
sigma(sigma==0) = 1e-6;

yRange = (-fix(dims(1)/2)):(fix(dims(1)/2));
xRange = (-fix(dims(2)/2)):(fix(dims(2)/2));
zRange = (-fix(dims(3)/2)):(fix(dims(3)/2));

[yg,xg,zg] = ndgrid(yRange,xRange,zRange);
gaussY = exp(-(yg.^2)/(2*sigma(1).^2));
gaussX = exp(-(xg.^2)/(2*sigma(2).^2));
gaussZ = exp(-(zg.^2)/(2*sigma(3).^2));

gauss = gaussY.*gaussX.*gaussZ;

return
