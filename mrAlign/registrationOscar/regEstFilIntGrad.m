function [Int, Noise] = regEstFilIntGrad(inp, PbyPflag, lpf);
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
  lpf = conv([1 4 6 4 1]/16, [1 4 6 4 1]/16);
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
   inpB(:,:,k) = regPutBorde(inp(:,:,k), B, B, 2);
end

% estimates the intensity as the local mean
Int = regConvXYZsep(inpB, 'repeat', lpf, lpf, lpfZ);

% estimates the noise as the mean local variance
for k=1:size(Int,3)     % adding border to the estimated intensity
   IntB(:,:,k) = regPutBorde(Int(:,:,k), B, B, 2);
end
Noise = regConvXYZsep((inpB-IntB).^2, 'repeat', lpf, lpf, lpfZ);


