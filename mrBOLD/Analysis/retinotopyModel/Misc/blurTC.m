function [blurred_tc]=blurTC(tc,fwhm,medfiltsize,zeropadd)
% blurTC - blur time intensity curves
%
% [blurred_tc]=blurtic(tc,fwhm,medfiltsize,zeropadd);
%
% 2008/02 SOD: wrote it.

if ~exist('tc','var') || isempty(tc),
    error('Need time series');
end
if ~exist('fwhm','var') || isempty(fwhm),
    fwhm = 0;
end
if ~exist('medfiltsize','var') || isempty(medfiltsize),
    medfiltsize = 0;
end
if ~any([fwhm medfiltsize]),
    blurred_tc = tc;
    return
end
if ~exist('zeropadd','var') || isempty(zeropadd),
    zeropadd = ceil(fwhm*4);
end

% sometimes we input single precision
convert_back_to_single = false;
if isa(tc,'single')
    convert_back_to_single = true;
    tc=double(tc);
end

% blurring kernel
if fwhm > 0,
   sigma=fwhm/2.36;
   tp=(1:size(tc,1)+zeropadd)';

   Ctp=round(numel(tp)/2);
   gaussian = exp( -(tp-Ctp).^2/(2*sigma*sigma) );
   gaussian_fft=fft(gaussian-mean(gaussian));
   norm_gaussian_fft2=gaussian_fft./max(gaussian_fft);
   norm_gaussian_fft=norm_gaussian_fft2*ones(1,size(tc,2));
end;

% remove dc
data=tc;
meandata=ones(size(tc,1),1)*mean(data);
mdata=data-meandata;
% median filter
if medfiltsize > 0,
   mdata=medfilt1(mdata,medfiltsize);
end;
% gaussian filter
if fwhm > 0,
   fft_data_blur = fft(mdata,size(tc,1)+zeropadd).*abs(norm_gaussian_fft);
   mdata  = real(ifft(fft_data_blur));
end
% add dc
blurred_tc  = mdata(1:size(tc,1),:)+meandata;

if convert_back_to_single,
    blurred_tc = single(blurred_tc);
end

return

