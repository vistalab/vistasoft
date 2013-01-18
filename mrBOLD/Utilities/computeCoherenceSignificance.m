function PVal=computeCoherenceSignificance(TH,N)
% PVal=computeCoherenceSignificance(TH,N)
% 
% PURPOSE:
% Returns a rough estimate of the significance value of a 
% coherence threshold. 'Rough' because it assumes 
% gaussian noise and takes no account of the fact that voxels 
% are spatially correlated with their neighbours
% and have non-delta temporal auto-correlation functions.
%
% From Bantettini el al, 1993, 
% Processing Strategies for Time Course Data Sets
% MRM 30:161-173 (1993) pp 171
% 
% ARW 01/14/03 Wrote it
% $Author: wade $
% $Date: 2003/01/14 23:07:47 $

if (~exist('TH','var') | ~exist('N','var'))
    error('You must pass both a coherence threshold "TH" and the number of TRs "N"');
end

% It's just the complimentary error function...
PVal=1-erf(TH*sqrt(N/2))+eps;

    