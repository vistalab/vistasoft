function [h]=rmHrfTwogammas(t,params)
% Create an HRF based on the SPM two gamma model. 
% 
% [h]=rmHrfTwogammas(t,params)
% 
% t: a range of latencies
% params(1): peak gamma 1
% params(2): fwhm gamma 1
% params(3): peak gamma 2
% params(4): fwhm gamma 2
% params(5): dip
% Final hrf is:   gamma1/max(gamma1)-dip*gamma2/max(gamma2)
% from Glover, NeuroImage, 9:416-429
%
%
% Example 1 Use defaults.
%   tr = 1.5;
%   t  = tr * (0:50);
%   h = rmHrfTwogammas(t);
%   figure; plot(t, h); 
%   xlabel('time (seconds)'); 
%   ylabel('response');
%
% Example 2 Put in your own parameters
%   tr = 1.5;
%   t  = tr * (0:50);
%   params = [3 5 15 20 0.2];
%   h1 = rmHrfTwogammas(t);
%   h2 = rmHrfTwogammas(t, params);
%   figure; plot(t, h1, 'r', t, h2, 'g'); 
%   xlabel('time (seconds)'); 
%   ylabel('response');
%   legend('Default', 'Subject specfic');

% 2.11.2011 JW: Cropped out of rfConvolveTC and made into a separate function 

% If no HRF parameters input, use defauls
if nargin < 2 || isempty(params) 
    params = [5.4 5.2 10.8 7.35 0.35];
end

% params
peak1 = params(1);
fwhm1 = params(2);
peak2 = params(3);
fwhm2 = params(4);
dip   = params(5);

% sanity check
if(peak1 == 0 || fwhm1 ==0)
    fprintf('[%s]: zero params',mfilename);
    params, %#ok<NOPRT>
    return;
end

% Taylor:
alpha1=peak1^2/fwhm1^2*8*log(2);
beta1=fwhm1^2/peak1/8/log(2);
gamma1=(t/peak1).^alpha1.*exp(-(t-peak1)./beta1);

if peak2>0 && fwhm2>0
    alpha2=peak2^2/fwhm2^2*8*log(2);
    beta2=fwhm2^2/peak2/8/log(2);
    gamma2=(t/peak2).^alpha2.*exp(-(t-peak2)./beta2);
else
    gamma2=min(abs(t-peak2))==abs(t-peak2);
end
h = gamma1-dip*gamma2;
%h = h./sum(h);

return;
