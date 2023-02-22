function noiseBand = GetNoiseBand(view, scan)
%
% noiseBand = GetNoiseBand(view, scan)
%
% Gets the noise band, the frequency-domain indices of that% portion of the power spectrum to be used to estimate the% noise power. Returns value of zero to indicate default% behavior: use ALL power-spectral samples to estimate noise.
%
% Ress, 8/30/02
global dataTYPES;
if ~exist('scan', 'var')
    if isfield(view, 'ui')
        scan = getCurScan(view);
    else
        scan = 1;
    end
endnoiseBand = 0; 
if isfield(dataTYPES(view.curDataType).blockedAnalysisParams(scan), 'noiseBand')  noiseBand = dataTYPES(view.curDataType).blockedAnalysisParams(scan).noiseBand;end


