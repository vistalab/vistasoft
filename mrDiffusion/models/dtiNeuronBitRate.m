function [delay,maxBitRate,energy] = dtiNeuronBitRate(radius, length, meanFiringRate, myelinated)
%
% [delay,maxBitRate,energy] = dtiNeuronBitRate(radius, length, meanFiringRate, [myelinated=true])
%
% Returns neural conduction delay in msec, the maximum bit-rate, and the energy consumption
% given the outer radius (in micrometers), the length (in millimeters), and the mean firing
% rate (in spikes/sec).
%
% Energy requirements are specified in amol glucose / action potential.
%
% See:
%   Brenner et. al. (2000). Synergy in a neural code. Neural Comput.
%   Wang et. al. (2008). Functional Trade-Offs in White Matter Axonal Scaling. J. Neurosci.
%   (The main reference that works out the bit-rate.)
%
% Also see:
%   Timing jitter vs. radius: Swadlow (2000). Time and the brain (R. Miller, ed.)
%   (We assume that timing jitter is +/-10% or the total conduction delay.)
%
% 2009.02.06 RFD wrote it.

if(~exist('myelinated','var') || isempty(myelinated))
    myelinated = true;
end

[speed,energyPerMm] = dtiNeuralConductionSpeed(radius, myelinated);

delay = 1 ./ (speed ./ length);
% delay is in ms- we need seconds, thus the 1000
energy = energyPerMm.*length;
maxBitRate = log2(1./(meanFiringRate.*0.2.*(delay./1000)));

return;
