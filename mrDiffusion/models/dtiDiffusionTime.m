function diffusionTime = dtiDiffusionTime(b, gradDuration, gradStrength)
%
% diffusionTime = dtiDiffusionTime(b, gradDuration, gradStrength)
%
% gradStrength in milliTesla/meter (= 10*Gauss/cm; typically 40 mT/m)
% gradDuration in milliseconds (typically 17-22 ms)
% b = millisecons/micrometer^2 (typically 0.8 - 1.2)
%

if(~exist('gradStrength','var')||isempty(gradStrength))
    gradStrength = 40;
end

gyroMagRatio = 42.576; % MHz/T (for Hydrogen)

gamma = 2*pi*gyroMagRatio*1e6*1e-3; % convert to 1/ms/T (Hz = cycles/sec, 1 cycle = 2pi = 2pi/sec)
G = gradStrength*1e-3*1e-6;         % convert to T/um
d = gradDuration;

% b = gamma^2 * G^2 * d^2 * (D-d/3)

D = b/(gamma^2 * G^2 * d^2) + d/3;

diffusionTime = D;

return