function img = dtiSmooth3(img, sigma)
% img = dtiSmooth3(img, sigma)
%
% Gaussian smoothing (faster than matlab's smooth3)
%
% NOTE: We should add some zero-padding to avoid wrap-around issues.

persistent gauss;
persistent sigmaCache;
persistent dimsCache;

if(numel(sigma==1))
    sigma = [sigma sigma sigma];
end
if(all(sigma<=0))
    return;
end
dims = size(img);
if ~isa(img, 'double'), type = class(img); img = double(img); end
% there should be a more elegant way of preserving the image intensity
% range!
scale = max(abs(img(:)));
if(scale==0), return; end

if(isempty(gauss) || numel(sigma)~=numel(sigmaCache) || any(sigma~=sigmaCache) || numel(dims)~=numel(dimsCache) || any(dims~=dimsCache))
    gauss = newGauss(dims, sigma);
    sigmaCache = sigma;
    dimsCache = dims;
end

% Allow for 4d timeseries or 5d tensor data.
for(ii=1:size(img,4))
    for(jj=1:size(img,5))
        ft = fftshift(fftn(img(:,:,:,ii,jj)));
        ft = gauss.*ft;
        img(:,:,:,ii,jj) = real(ifftn(ifftshift(ft)));
    end
end
img = img./max(abs(img(:))).*scale;

if exist('type', 'var')
	% we had a non-double matrix, convert back
	img = feval(type, img);
end
return;


function gauss = newGauss(dimSrc,variance)
gaussx = myGausswin(dimSrc(1),variance(1));
gaussy = myGausswin(dimSrc(2),variance(2));
gaussz = myGausswin(dimSrc(3),variance(3));
gaussxy = gaussx*gaussy';
gauss = repmat(gaussxy,[1 1 dimSrc(3)]);
for i = 1:dimSrc(1)
    for j = 1:dimSrc(2)
        gauss(i,j,:) = gaussxy(i,j)*gaussz;
    end
end
return

function w = myGausswin(n, alpha)
% alpha is 1/stdev (width of the gaussian in Fourier space).
k = [-(n-1)/2:(n-1)/2];
w = exp((-1/2)*(alpha * k/(n/2)).^2)';
% Make sure the peak is at 1 so that we'll preserve to DC level
w(w==max(w)) = 1;
return
