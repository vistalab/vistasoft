function params = er_getParams(vw,scan,dt)
% params = er_getParams(vw,[scan],[dt]):
%
% Get the event-related analysis params
% for the current scan, stored in dataTYPES'
% eventAnalysisParams subfield. If some of 
% these fields are absent, initialize them 
% to reasonable guess values (usually from er_defaultParams). Returns params
% in a 'params' struct. 
%
% A lot of the newer params are used for
% er_chopTSeries, and the time course UI.
%
% scan defaults to view's current scan.
%
% ras 12/04
% dar 03/07 - nixxed calls which were redundant with er_defaultParams.
% Defaults are only called in one place now, and we're guaranteed to
% carryover all fields.  Big difference, if field already exists, but is
% empty, will leave as such (not likely to happen).
global dataTYPES;

if notDefined('vw'),        vw = getCurView;                        end
if notDefined('scan'),      scan = viewGet(vw, 'curScan');          end
if notDefined('dt'),        dt = viewGet(vw, 'Current Data Type');	end

if ischar(dt), dt = existDataType(dt); end

params = dtGet(dataTYPES(dt),'Event Analysis Params', scan);

defaults = er_defaultParams;

% set relevant missing parameters to defaults
% sets non-existent fields to the values specified by er_defaultParams.
params = mergeStructures(defaults, params); 

% set other missing parameters to "best guess"
% frame period:
% this is redundant w/ the scan params, but since
% I use these event params independent of mrVista and
% dataTYPES, we'll want it here too:
if ~isfield(params,'framePeriod')  || isempty(params.framePeriod)
    params.framePeriod = dtGet(dataTYPES(dt), 'Frame Period', scan);
end

% parfiles:
% this is also redundant w/ the scan params, but is essential
% for event-related analyses
if ~isfield(params,'parfiles')  || isempty(params.parfiles)
    params.parfiles = dtGet(dataTYPES(dt), 'Par File', scan); 
%     scanParams(scan).parfile;
    
    if ischar(params.parfiles), params.parfiles = {params.parfiles}; end
end

return