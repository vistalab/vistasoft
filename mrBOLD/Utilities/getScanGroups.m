function [u, ind, baseDataTYPE] = getScanGroups(vw, baseDT, confirm)
% Group the scans within a dataTYPE into subgroups with identical annotations.
% The number of subgroups equals the number of scans with unique
% annotations.
%
% [u, ind, baseDataTYPE] = getScanGroups(vw, baseDT)
%
% Purpose: 
%   Return the list of unique scan annotatons (u) and the corresponding scan
%   numbers (ind). This is useful if you want to do calculations on all
%   scans with the same annotation (e.g., you might want to make averages
%   of these scans, etc.).
%
% Example
%   [u, ind, baseDataTYPE] = getScanGroups;

% var check
mrGlobals;
%----------------------------------------------------------------------
% variable check
if notDefined('vw'),      vw = getCurView;                       end
if notDefined('baseDT'),  baseDT = viewGet(vw, 'curdatatype');   end
if notDefined('confirm'), confirm = false;                       end
%----------------------------------------------------------------------

% set view to base dataTYPE
vw = viewSet(vw, 'currentDataTYPE', baseDT);

% get the dataTYPE name
baseDataTYPE = dtGet(dataTYPES(baseDT), 'name');

% count the scans
nScans = viewGet(vw, 'nScans');

% get the annotation for each scan
annotation = cell(1,nScans);
for scan = 1:nScans;
    annotation{scan} =  dtGet(dataTYPES(baseDT), 'annotation', scan);
end

% get a list of the unique scan annotations
u = unique(annotation);

% count them
nGroups = length(u);

% get the scan numbers that correspond to each unique scan
ind = cell(1,nGroups);
for scan =1:nGroups;
    ind{scan} = find(strcmp(u{scan},annotation));
end

% confirm the groupings
if confirm
    for group = 1:nGroups
        q{group}  = [u{group} sprintf('\n') ...
            sprintf('%s scans ', baseDataTYPE)...
            num2str(ind{group})...
            sprintf(' -> Group %d\n', group)];
    end
    theanswer = questdlg(q, mfilename);
    if ~isequal(theanswer, 'Yes')
        fprintf('[%s]: Aborting....\n', mfilename); 
        u = []; ind = []; baseDataTYPE =[];
    end
end

return
