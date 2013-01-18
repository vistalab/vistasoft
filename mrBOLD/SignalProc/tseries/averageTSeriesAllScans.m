function vw = averageTSeriesAllScans(vw, baseDT, confirm)
% Average time series of each set of scans with the same annotation.
%  vw = averageAllTSeries([vw], [baseDT], [confirm])
% 
%  vw: mrVista view struct
%  baseDT: dataTYPE number from which to make the averages
%  confirm: boolean. if false, proceed without user ok. useful for scripting
% Example: 
%   vw = getCurView;
%   baseDT = 1;
%   vw = averageTSeriesAllScans(vw, baseDT);
%
%  JW: Jan, 2009

mrGlobals;
%----------------------------------------------------------------------
% variable check
if notDefined('vw'),      vw      = getCurView;                     end
if notDefined('baseDT'),  baseDT  = viewGet(vw, 'dataTypeNumber');  end
if notDefined('confirm'), confirm  = true;                          end
%----------------------------------------------------------------------

% group the scans by annotation
[group.name, group.indices, baseDataTYPE] = getScanGroups(vw, baseDT, confirm);
if isempty(group.name), return; end

% count them
nAverages = length(group.name);

% make the averages
for scan = 1:nAverages
    str  = [sprintf('Average of %s %s: Scans', baseDataTYPE, ...
        group.name{scan}) num2str(group.indices{scan})];    
    vw = averageTSeries(vw, group.indices{scan}, [],str);
end

% Done
return