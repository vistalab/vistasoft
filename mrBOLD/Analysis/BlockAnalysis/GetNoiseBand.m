function noiseBand = GetNoiseBand(view, scan)
% noiseBand = GetNoiseBand(view, scan)
%
% Purpose:
% Gets the noise band, the frequency-domain indices of that
% portion of the power spectrum to be used to estimate the noise power.
% Returns value of zero indicates default behavior: use ALL power-spectral samples.
%
% Ress, 8/30/02
% Rory, 05/2007: sometimes this can be set to empty. (I believe this
% comes from computeCorAnal2Freq, but can't find a good place to fix
% that code.) If so, just revert to the default 0 flag, so all power
% spectra are used as a noise band.
%
global dataTYPES
if ~exist('scan', 'var')
	if isfield(view, 'ui')
		scan = getCurScan(view);
	else
		scan = 1;
	end
end

verbose = prefsVerboseCheck;

noiseBand = 0;
if isfield(dataTYPES(view.curDataType).blockedAnalysisParams(scan),'noiseBand')
	noiseBand = dataTYPES(view.curDataType).blockedAnalysisParams(scan).noiseBand;
	if noiseBand~=0  & verbose >= 2
		fprintf(1,'[%s]:Using noise band.\n',mfilename);
	end
end

if isempty(noiseBand)
	noiseBand = 0;
end

return;
