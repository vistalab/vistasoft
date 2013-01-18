function params = retinoGetParams(vw, dt, scan)
% Get visual field mapping ("retinotopic", though it doesn't need
% to be) parameters for the selected scan.
%
% params = retinoGetParams(vw, <dt, scan>);
%
% dt and scan specify the data type and scans to use, and
% default to the view's current dt/scan if omitted.
%
% The parameters are stored in 
%   dataTYPES(dt).blockedAnalysisParameters(scan).visualFieldMap.
%
% Use retinoSetParams to update the parameters.
%
%
% ras, 01/06: testing the waters if this code is needed. I see many
% other places where similar parameters are set, but none of them
% seem immediately useable to me.
if notDefined('vw'),    vw = getCurView;               end
if notDefined('dt'),    dt = viewGet(vw, 'curdt');     end
if notDefined('scan'),  scan = viewGet(vw, 'curscan'); end

mrGlobals;

if ischar(dt),    dt = existDataType(dt);               end

if checkfields(dataTYPES(dt), 'blockedAnalysisParams', 'visualFieldMap') && ...
    ~isempty(dataTYPES(dt).blockedAnalysisParams(scan).visualFieldMap)
        params = dataTYPES(dt).blockedAnalysisParams(scan).visualFieldMap;
else
    params = [];
end

return
