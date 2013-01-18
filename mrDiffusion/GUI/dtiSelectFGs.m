function sList = dtiSelectFGs(handles,promptStr)
%
%  sList = dtiSelectFGs(handles,promptStr)
%
%Author: Wandell
%Purpose:
%   Select subset of Fiber Groups using a list diaolog

if ieNotDefined('promptStr'), promptStr = 'Select FGs '; end

% Empty selected list
sList = []; 
if(isempty(handles.fiberGroups)), disp('No FGs to delete!'); return; end

fgNames = {handles.fiberGroups.name};
nFGs = length(fgNames);

% For some purposes Bob adjusted the fgNames on the fly.  For general
% selection, I don't think we should translate the names.  For example,
% when writing out, he replaces blank with _.  Here, he adds some more
% description to the name.
for(ii=1:nFGs) 
    c = getColorString(handles.fiberGroups(ii).colorRgb);
    fgNames{ii} = [fgNames{ii},' (',c,')'];
end

[sList,ok] = listdlg('PromptString', promptStr, ...
    'SelectionMode', 'multiple', ...
    'ListString', fgNames, 'ListSize', [400 400]);

if ~ok, sList = []; end

return;