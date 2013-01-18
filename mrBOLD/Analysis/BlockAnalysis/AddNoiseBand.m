function AddNoiseBand(noiseBand)

% AddNoiseBand(noiseBand)
% 
% Initialize noise band fields in the dataTYPES structure.
% Input noiseBand can have several forms:
% scalar          Sets bandwidth of frequency components, centered at stimulus frequency 
%                 to use in corAnal. Same bandwidth is applied to all scans.
% vector          Specifies specific frequency components, in cycles/scan, to use in corAnal.
%                 Same values are applied to all scans.
% cell array      To apply different noiseBands to different scans, provide the desired
%                 scalar or vector specification in a cell vector array with length equal to
%                 the number of scans.
% Examples:
% 1. To specify a noise bandwidth of 10 cycles/scan for all scans, use
%        AddNoiseBand(10)
% 2. To specify an asymmetric noise band starting 3 cycles/scan below through 7 cycles/scan
%    above the stimulus frequency, use
%        AddNoiseBand(-3:7);
% 3. To specify a particular asymmetric noise band for the first and last scans, and symmetric
%    noise bands for scans 2:9, use
%        AddNoiseBand({(-5:15), repmat({11}, 1, 8), (-5:15)})
%
% Ress, 3/03

global dataTYPES

if ~exist('noiseBand', 'var'), noiseBand = 0; end

nTypes = length(dataTYPES);
if ~iscell(noiseBand), noiseBand = {noiseBand}; end

if length(noiseBand) == 1, noiseBand = repmat(noiseBand, nTypes, 1); end
if length(noiseBand) ~= nTypes
  Alert('Must specify single noise band for all scans, or all noise bands for all scans');
  return
end

dT = dataTYPES;
for iT=1:nTypes
  nScans = length(dT(iT).blockedAnalysisParams);
  nB = noiseBand{iT};
  if ~iscell(nB), nB = {nB}; end
  
  if length(nB) == 1, nB = repmat(nB, nScans, 1); end
  if length(noiseBand) ~= nTypes
    Alert('Must specify single noise band for all scans, or all noise bands for all scans');
    return
  end
  % Put noise bands into data structure
  for iS=1:nScans, dT(iT).blockedAnalysisParams(iS).noiseBand = nB{iS}; end
end

dataTYPES = dT;

saveSession;
