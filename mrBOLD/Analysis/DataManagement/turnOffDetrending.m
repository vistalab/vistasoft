function turnOffDetrending(vw, dt, scans);
% Turn off all detrending options for the specified view and scans.
%  
%   turnOffDetrending([view=cur view], [dt=cur data type], [scans=all scans in data type]);
%
% A small helper function to modify the settings in dataTYPES without
% having to manually type several hard-to-remember field names (or 
% point-and-click through several dialogs).
%
% ras, 02/2009.
if notDefined('vw'),	vw = getCurView;			end
if notDefined('dt'),	dt = vw.curDataType;		end
if notDefined('scans'),	scans = 1:numScans(vw);		end

if ischar(dt), dt = existDataType(dt);				end

if isempty(dt)
	error('Data Type not found.')
end

mrGlobals;

for s = scans
	dataTYPES(dt).blockedAnalysisParams(s).detrend = 0;
	dataTYPES(dt).blockedAnalysisParams(s).inhomoCorrect = 0;	
	dataTYPES(dt).blockedAnalysisParams(s).temporalNormalization = 0;		
	

	dataTYPES(dt).eventAnalysisParams(s).detrend = 0;
	dataTYPES(dt).eventAnalysisParams(s).inhomoCorrect = 0;	
	dataTYPES(dt).eventAnalysisParams(s).temporalNormalization = 0;		
end

if prefsVerboseCheck >= 1
	fprintf('[%s]: Turned off detrending for %s scans %s.\n', ...
			mfilename, dataTYPES(dt).name, num2str(scans));
end

saveSession;

return
