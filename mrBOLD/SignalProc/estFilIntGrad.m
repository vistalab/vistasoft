function [Int, Noise] = estFilIntGrad(inp, PbyPflag, lpf);
% regEstFilIntGrad - Estimates the intensity gradient, using local mean
%
%    [Int, Noise] = regEstFilIntGrad(inp, <PbyPflag>, <lpf>);
%
% Inputs:
%  inp - input inplanes affected by the intensity gradient
%  PbyPflag - operates plane by plane if activated (default 0)
%  lpf - low pass filter (applied separably to x,y,z) used to
%        compute the local mean
%
% Outputs:
%  Int   - Estimated intensity
%  Noise - Estimated power-spatial distribution of the noise, as the
%          local variance
%
% Oscar Nestares - 5/99
%

% default low-pass filter
if ~exist('lpf')
  x = -15:15;
  sigma = 4;   % spread of the lowpass filter
  lpf = 1/sqrt(2*pi*sigma^2) * exp(-(1/2)*x.^2 / sigma^2);
  lpf = lpf/sum(lpf);
end

lpfZ = lpf;
if exist('PbyPflag')
   if PbyPflag
      lpfZ = 1;
   end
end

B = (length(lpf)-1)/2;

% adding border to the original inplanes
for k=1:size(inp,3)
  inp1 = inp(:, :, k);
  inp1(isnan(inp1)) = min(inp1(:));
  inpB(:,:,k) = regPutBorde(inp1, B, B, 2);
end

% estimates the intensity as the local mean
Int = regConvXYZsep(inpB, 'repeat', lpf, lpf, lpfZ);

% estimates the noise as the mean local variance
for k=1:size(Int,3)     % adding border to the estimated intensity
   IntB(:,:,k) = regPutBorde(Int(:,:,k), B, B, 2);
end
Noise = regConvXYZsep((inpB-IntB).^2, 'repeat', lpf, lpf, lpfZ);

% minimum noise
II = find(~isnan(inp));
sigma2 = (median(inp(II))-4*median(abs(inp(II)-median(inp(II)))))^2;

% correction
InvInt = Int./(Int.^2 + 3*Noise + sigma2);
Int = 1./InvInt;


return

clear
load testdata
inp(find(isnan(inp))) = 0;
[int, noise] = regEstFilIntGrad(inp);
inpc = inp./int;
sinpc = reshape(inpc, [size(inp,1) size(inp,2)*size(inp,3)]);
figure(1)
imshow(sinpc, [0.5 1.5], 'notruesize')
figure(2)
II = find(inpc~=0);
hist(inpc(II),256)
