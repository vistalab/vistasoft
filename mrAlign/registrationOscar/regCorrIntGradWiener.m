function inpC = regCorrIntGradWiener(inp, Int, Noise);
% regCorrIntGradWiener - corrects for the intensity gradient applying a
%                     wiener-like filtering.
%
%    inpC = regCorrIntGradWiener(inp, Int, Noise);
%  
% INPUT:
%   inp   - original inplanes
%   Int   - estimated intensity
%   Noise - estimated power-spatial distribution of the noise
%
% Oscar Nestares - 5/99
%

% minimum noise
sigma2 = mean(Noise(:))/2;

% correction
inpC = inp.*Int ./ (Int.^2 + Noise + sigma2);
